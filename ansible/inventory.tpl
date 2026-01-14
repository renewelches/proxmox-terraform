[all]
%{ for name, ip in containers ~}
${name} ansible_host=${ip}
%{ endfor ~}

[containers]
%{ for name, ip in containers ~}
${name} ansible_host=${ip}
%{ endfor ~}

[all:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3
