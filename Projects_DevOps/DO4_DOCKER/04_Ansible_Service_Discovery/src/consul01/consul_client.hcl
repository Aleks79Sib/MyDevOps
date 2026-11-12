                                                                  
server    = false                                                                              
datacenter = "dc1"                                                                             
data_dir   = "/tmp/consul"                                                                     
log_level  = "INFO"                                                                            
                                                                                              
advertise_addr = "{{ GetInterfaceIP \"eth1\" }}"                                 
bind_addr      = "0.0.0.0"                                                                     
                                                                                              
retry_join = ["192.168.121.200"]     # IP сервера, к которому подключаться                       
                                                                                              
addresses {                                                                                    
  http = "0.0.0.0"                                                                             
}                                                                                              
                                                                                              
connect {                                                                                      
  enabled = true                                                                               
}                                                                                              
                                                                                              
ports {                                                                                        
  grpc = 8502                                                                                  
}
