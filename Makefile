apply:
	terraform apply -auto-approve

# work around: ibm_is_instance change of user_data causes a crash
# https://github.ibm.com/blueprint/bluemix-terraform-provider-dev/issues/661
reapply:
	terraform taint ibm_is_floating_ip.floatingip
	terraform taint ibm_is_instance.instance
	terraform apply -auto-approve

# test the following:
#   httpd was installed
#   the computer has access to the internet (see the cloud-config.yml, look for bash -x /init.bash)
#   the terraform provisioner works by replacing the contents of bootstrap.min.css file with hi
test_public:
	./test_public.bash

# test the private instance
#   httpd was installed (this comes from the ibm mirror)
#   computer does not have access to the internet to install other stuff like python
test_private:
	./test_private.bash
