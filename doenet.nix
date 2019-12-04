{
  network = {
    description = "api.doenet.cloud";
  };
  
  defaults = {
    imports = [ ./vultr.nix ];
  };

  ################################################################
  webserver = { config, pkgs, nodes, ... }:
  let
    theServer = pkgs.callPackage ../lrs/default.nix { yarn2nix = pkgs.yarn2nix-moretea; };
  in rec {
    deployment.targetHost = "45.77.159.207";
    networking.privateIPv4 = "10.1.96.4"; 

    networking.extraHosts = "${nodes.database.config.networking.privateIPv4} db";
    
    environment.systemPackages = with pkgs; [
      mongodb redis theServer
    ];
    
    services.nginx = {
      enable = true;
      
      # Use recommended settings
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
    
    services.nginx.virtualHosts."api.doenet.cloud" = {
      forceSSL = true;
      enableACME = true;
      default = true;
      root = "/var/www/api.doenet.cloud";
      locations = {
        "/".proxyPass = "http://localhost:${systemd.services.node.environment.PORT}";
      };
    };

    security.acme.certs = {
      "api.doenet.cloud".email = "fowler@doenet.org";
    };

    systemd.services.node = {
      description = "node service";

      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
            
      environment = {
        PORT = "4000";
        NODE_ENV = "production";
        
        MONGODB_DATABASE = "lrs";
        MONGODB_PASS = nodes.database.config.services.mongodb.initialRootPassword;
        MONGODB_USER = "root";
        MONGODB_HOST = nodes.database.config.services.mongodb.bind_ip;
        MONGODB_PORT = 27017;

        REDIS_HOST = nodes.database.config.services.redis.bind;
        REDIS_PORT = nodes.database.config.services.redis.port;
        REDIS_PASS = nodes.database.config.services.redis.requirePass;
        SECRET = builtins.readFile ./secret.key;
      };
      
      serviceConfig = {
        ExecStart = "${theServer}/bin/doenet-lrs";
        User = "doenet";
        Restart = "always";
      };
    };
   
    users.extraUsers = {
      doenet = { };
    };
   
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };

  ################################################################
  database = { config, pkgs, ... }:
  rec {
    deployment.targetHost = "149.28.42.92";
    networking.privateIPv4 = "10.1.96.4";
    
    services.redis = {
      enable = true;
      bind = networking.privateIPv4;
      port = 6379;
      requirePass = builtins.readFile ./redis.key;
    };
    
    services.mongodb = {
      enable = true;
      bind_ip = networking.privateIPv4;
      enableAuth = true;
      initialRootPassword = builtins.readFile ./mongodb.key;
    };

    networking.firewall.interfaces.ens7.allowedTCPPorts = [ services.redis.port 27017 ];
  };
}
