node_name = "consul-server"                                                                    
   server    = true                                                                               
   bootstrap = true                                                                               
   datacenter = "dc1"                                                                             
   data_dir   = "/tmp/consul"                                                                     
   log_level  = "INFO"                                                                            
                                                                                                  
   advertise_addr = "{{ GetInterfaceIP \"eth1\" }}"                                                              
   bind_addr      = "0.0.0.0"                                                                     
                                                                                                  
   ui_config {                                                                                    
     enabled = true                                                                               
   }                                                                                              
                                                                                                  
   addresses {                                                                                    
     http = "0.0.0.0"                                                                             
     dns  = "0.0.0.0"                                                                             
   }                                                                                              
                                                                                                  
   connect {                                                                                      
     enabled = true                                                                               
   }                                                                                              
                                                                                                  
   ports {                                                                                        
     grpc = 8502                                                                                  
   }

