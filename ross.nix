let
  awsKeyId = "AKIAI6QCDKDFAZFL5D5A"; # for fowler@rossprogram.org
  region = "us-east-2"; # for Ohio
  pkgs = import <nixpkgs> {};
in
{
  network.description = "api.rossprogram.org";

  resources.ec2KeyPairs.myKeyPair = {
    accessKeyId = awsKeyId;
    inherit region;
  };
  
  resources.ec2SecurityGroups.openPorts = { resources, ... }: {
    accessKeyId = awsKeyId;
    inherit region;
    rules = [
      { toPort = 22; fromPort = 22; sourceIp = "0.0.0.0/0"; } # SSH
      { toPort = 80; fromPort = 80; sourceIp = "0.0.0.0/0"; } # HTTP
      { toPort = 443; fromPort = 443; sourceIp = "0.0.0.0/0"; } # HTTPS
    ];
  };
  
  api = { resources, config, nodes, ... }:
  let
    # build the backend node app
    theServer = pkgs.callPackage ../backend/default.nix { yarn2nix = pkgs.yarn2nix-moretea; };
  in {
    # Cloud provider settings; here for AWS
    deployment.targetEnv = "ec2";
    deployment.ec2.accessKeyId = awsKeyId;
    deployment.ec2.region = region;
    deployment.ec2.instanceType = "t2.micro"; # a cheap one
    deployment.ec2.ebsInitialRootDiskSize = 30; # GB
    deployment.ec2.keyPair = resources.ec2KeyPairs.myKeyPair;
    deployment.ec2.associatePublicIpAddress = true;
    deployment.ec2.securityGroups = [ resources.ec2SecurityGroups.openPorts.name ];
    
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [
      pkgs.mongodb theServer
    ];
    
    services.mongodb.enable = true;
    
    services.nginx = {
      enable = true;
      
      # Use recommended settings
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
    
    services.nginx.virtualHosts."api.rossprogram.org" = {
      forceSSL = true;
      enableACME = true;
      default = true;
      root = "/var/www/api.rossprogram.org";
      locations = {
        "/".proxyPass = "http://localhost:${config.systemd.services.node.environment.PORT}/";
      };
    };

    security.acme.acceptTerms = true;
    
    security.acme.certs = {
      "api.rossprogram.org".email = "fowler@rossprogram.org";
    };
    
    systemd.services.node = {
      description = "node service";
      
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      
      environment = {
        PORT = "4000";
        NODE_ENV = "production";
        SECRET = builtins.readFile ./secret.key;
        API_BASE = "https://api.rossprogram.org/";
        SMTP_HOST = "email-smtp.us-east-1.amazonaws.com";
        SMTP_PORT = "465";
        SMTP_USER = "AKIAY4INV4Z4X3M2DKRS";
        SMTP_PASS = builtins.readFile ./smtp.key;
        STRIPE_SECRET = builtins.readFile ./stripe.key;
        STRIPE_PUBLIC = "pk_live_EVv0HE4EnEnGBfjY2iBzPnuS003Q0UNubO";
        STRIPE_ENDPOINT_SECRET=builtins.readFile ./stripe-endpoint.key;
        MONGODB_DATABASE = "ross";
        MONGODB_PORT = toString 27017;
      };
      
      serviceConfig = {
        ExecStart = "${theServer}/bin/rossprogram-api";
        User = "ross";
        Restart = "always";
      };
    };

    # for "security" do not run the node app as root
    users.extraUsers = {
      ross = {
        isNormalUser = true;
      };
    };
    
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}


