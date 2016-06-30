### Installing Ansible from git on Ubuntu 14.04

Install dependencies:
```
apt-get install python-yaml python-paramiko python-jinja2 python-httplib2
```

Download ansible source from git (**make sure have `--recursive` option**):
```
git clone https://github.com/ansible/ansible.git --recursive
```

Install ansible:
```
cd ansible && make && sudo make install
```

Now, Ansible should be installed:
```
# which ansible
/usr/local/bin/ansible

```

### Issues

- Issue 1

```
FAILED => module ping not found in configured module paths.  Additionally, core modules are missing. If this is a checkout, run 'git submodule update --init --recursive' to correct this problem
```

This usually indicates that you may have missed the --recursive option during the clone of Ansible and as such are missing a few things, such as the 'ping' module. That's OK it can be rectified by following the steps in the error. These suggest going to the root of the 'ansible' directory and running 'git submodule update --init --recursive', once you have done this you wil see git cloning back into the Ansible git and grabbing what was missed at the beginning. Now once that's finished, just re-run make install and all should be good!

- Issue 2

```
unsupported parameter for module: gather_subset
```

I had the same issue with pip installed ansible. Turned out it was because someone else had also installed ansible through apt, and it was looking in /usr/share/ansible for modules, which was picking up the outdated apt versions. Removing the apt installed ansible fixed my issue. 
```
rm -rf /usr/share/ansible
```

