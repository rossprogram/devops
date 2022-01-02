let
  awsKeyId = "AKIAI6QCDKDFAZFL5D5A"; # for fowler@rossprogram.org
  region = "us-west-1"; # to minimize latency for our users
  pkgs = import <nixpkgs> {};

  circlezPort = 7817;
  mumblePort = 64738;
  icePort = 6502;
in
{
  network.description = "circlez.rossprogram.org";

  resources.ec2KeyPairs.myKeyPair = {
    accessKeyId = awsKeyId;
    inherit region;
  };
  
  resources.ec2SecurityGroups.openCirclezPorts = { resources, lib, ... }: {
    accessKeyId = awsKeyId;
    inherit region;
    description = "Open ports for the Circle Z server";
    rules = [
      { toPort = 22; fromPort = 22; sourceIp = "0.0.0.0/0"; } # SSH
      { toPort = circlezPort; fromPort = circlezPort; sourceIp = "0.0.0.0/0"; }
    ];
  };

  circlez = { resources, config, nodes, ... }:
  let
    # build the backend node app
    app = pkgs.callPackage ../circle-z-server/default.nix { yarn2nix = pkgs.yarn2nix-moretea; };
  in {
    # Cloud provider settings; here for AWS
    deployment.targetEnv = "ec2";
    deployment.ec2.accessKeyId = awsKeyId;
    deployment.ec2.region = region;
    deployment.ec2.instanceType = "t2.micro"; # a cheap one
    deployment.ec2.ebsInitialRootDiskSize = 10; # GB
    deployment.ec2.keyPair = resources.ec2KeyPairs.myKeyPair;
    deployment.ec2.associatePublicIpAddress = true;
    deployment.ec2.securityGroups = [ resources.ec2SecurityGroups.openCirclezPorts.name ];

    environment.systemPackages = with pkgs; [
      pkgs.mongodb app
    ];
    
    services.mongodb.enable = true;

    systemd.services.node = {
      description = "node service";
      
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      
      environment = {
        NODE_ENV = "production";

        # this is what is provided to clients, i.e., what a user would
        # enter into mumble
        MUMBLE_SERVER="mumble.rossprogram.org";
        MUMBLE_PORT=toString mumblePort;

        # murmur is the mumble server, i.e., the IP where we use ice
        # to control murmur
        MURMUR_HOST="127.0.0.1";
        MURMUR_PORT=toString icePort;
        MURMUR_ICE_SECRET=builtins.readFile ./ice.key;
          
        PORT = toString circlezPort;
        SECRET = builtins.readFile ./secret.key;

        MONGODB_DATABASE = "circlez";
        MONGODB_PORT = toString 27017;

        AWS_ACCESS_KEY_ID=awsKeyId;
        AWS_SECRET_ACCESS_KEY=builtins.readFile ./aws-secret.key;
        
        PRIVATE_KEY_PEM=builtins.readFile ./private-key.pem;
        PUBLIC_CERT_PEM=builtins.readFile ./public-cert.pem;
      };
      
      serviceConfig = {
        ExecStart = "${app}/bin/circle-z-server";
        User = "node";
        Restart = "always";
      };
    };

    # for "security" do not run the node app as root
    users.extraUsers = {
      node = { };
    };
    
    networking.firewall.allowedTCPPorts = [ circlezPort ];
  };
}


