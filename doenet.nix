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
  in {
    deployment.targetHost = "45.77.159.207";

    networking.extraHosts = "${(builtins.head nodes.database.config.networking.interfaces.ens7.ipv4.addresses).address} db";
    networking.interfaces.ens7.ipv4.addresses = [ {
      address = "10.1.96.4";
      prefixLength = 20;
    } ];

    environment.systemPackages = with pkgs; [
      mongodb redis theServer
    ];
    
    services.nginx.enable = true;
    services.nginx.virtualHosts."api.doenet.cloud" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/api.doenet.cloud";
    };

    security.acme.certs = {
      "api.doenet.cloud".email = "fowler@doenet.org";
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
