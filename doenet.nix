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
    # build the backend node app
    theServer = pkgs.callPackage ../service/default.nix { yarn2nix = pkgs.yarn2nix-moretea; };
  in {
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
        "/".proxyPass = "http://localhost:${config.systemd.services.node.environment.PORT}";

        "=/iframe.js" = {
          root = "${theServer}/dist/";
          extraConfig = ''
            etag off;
            add_header etag "\"${builtins.substring 11 32 theServer.outPath}\"";
          '';
        };
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

        SECRET = builtins.readFile ./secret.key;
        
        MONGODB_DATABASE = "lrs";
        MONGODB_USER = "lrs";
        MONGODB_PASS = nodes.database.config.services.mongodb.initialRootPassword;
        MONGODB_HOST = nodes.database.config.services.mongodb.bind_ip;
        MONGODB_PORT = toString 27017;

        REDIS_HOST = nodes.database.config.services.redis.bind;
        REDIS_PORT = toString nodes.database.config.services.redis.port;
        REDIS_PASS = nodes.database.config.services.redis.requirePass;

        LOGGLY_TOKEN = builtins.readFile ./loggly.key;
        LOGGLY_SUBDOMAIN = "doenet";
      };
      
      serviceConfig = {
        ExecStart = "${theServer}/bin/doenet-service";
        User = "doenet";
        Restart = "always";
      };
    };

    # for "security" do not run the node app as root
    users.extraUsers = {
      doenet = { };
    };
   
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };

  ################################################################
  database = { config, pkgs, ... }:
  {
    deployment.targetHost = "149.28.42.92";
    networking.privateIPv4 = "10.1.96.3";
    
    services.redis = {
      enable = true;
      bind = config.networking.privateIPv4;
      port = 6379;
      requirePass = builtins.readFile ./redis.key;
    };

    services.mongodb = {
      enable = true;
      bind_ip = config.networking.privateIPv4;
      enableAuth = true;
      initialRootPassword = builtins.readFile ./mongodb.key;
    };

    networking.firewall.interfaces.ens7.allowedTCPPorts = [ config.services.redis.port 27017 ];
  };
}
