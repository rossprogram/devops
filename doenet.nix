{
  network = {
    description = "api.doenet.cloud";
  };
  
  defaults = {
    imports = [ ./vultr.nix ];
  };
  
  webserver = { config, pkgs, ... }:
  {
    deployment.targetHost = "45.77.159.207";
    
    services.httpd.enable = true;
    services.httpd.adminAddr = "alice@example.org";
    services.httpd.documentRoot = "${pkgs.valgrind.doc}/share/doc/valgrind/html";
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
  
  database = { config, pkgs, ... }:
  {
    deployment.targetHost = "149.28.42.92";
      
    services.httpd.enable = true;
    services.httpd.adminAddr = "alice@example.org";
    services.httpd.documentRoot = "${pkgs.valgrind.doc}/share/doc/valgrind/html";
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
