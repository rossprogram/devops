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

    networking.extraHosts = "${(builtins.head nodes.database.config.networking.interfaces.ens7.ipv4.addresses).address} db";
    networking.interfaces.ens7.ipv4.addresses = [ {
      address = "10.1.96.4";
      prefixLength = 20;
    } ];

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
      # Start the service after the network is available
      after = [ "network.target" ];
      environment = {
        PORT = "4000"; # FIXME
      };
      serviceConfig = {
        ExecStart = "${theServer}/bin/doenet-lrs";
        User = "doenet";
        Restart = "always";
      };
      wantedBy = [ "default.target" ];
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
    
    networking.interfaces.ens7.ipv4.addresses = [ {
      address = "10.1.96.3";
      prefixLength = 20;
    } ];

    services.redis = {
      enable = true;
      bind = (builtins.head networking.interfaces.ens7.ipv4.addresses).address;
      port = 6379;
      requirePass = "HjIDNDNfoVoCF2AJwy";
    };
    
    services.mongodb = {
      enable = true;
      bind_ip = (builtins.head networking.interfaces.ens7.ipv4.addresses).address;
      enableAuth = true;
      initialRootPassword = "VKVdXULvL60hkO4L";
    };

    networking.firewall.interfaces.ens7.allowedTCPPorts = [ services.redis.port 27017 ];
  };
}
