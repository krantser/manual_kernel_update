# **Используемые инструменты**

Для создания образа операционной системы CentOS Linux с обновлённым ядром
использовались следующие инструменты:

- **Debian 9.12**
- **VirtualBox 6.0.20**
- **Vagrant 2.2.7**
- **Packer 1.5.5**
- **Kernel Linux 5.4.36**
- **CentOS 7.7**
- **Git 2.11.0**

# **Установка недостающего в системе ПО**

### **Установка Vagrant**

Для создания и конфигурирование виртуальной среды воспользуемся таким програмным
обеспечением как `Vagrant`. Установка производится с помощью команд, представленных
ниже:

```
wget https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.deb
root# dpkg -i vagrant_2.2.7_x86_64.deb
```

Далее для работы специальных функций VBoxGuestAdditions необходимо установить
плагин для Vagrant:
```
vagrant plugin install vagrant-vbguest
```


### **Установка Packer**

Что бы создавать образы виртуальных машин используем `Packer`. Ниже приведены
команды для его установки:

```
wget https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip
root# unzip packer_1.5.5_linux_amd64.zip -d /usr/local/bin/
root# chmod +x /usr/local/bin/packer
```

### **Клонирование репозитория с инструкцией, конфигурациями и скриптами**

Далее клонируем репозиторий с файлом конфигурации Vagrant, а также конфигурацией
и скриптами для Packer после того, как сделали форк в свой аккаунт:

```
git clone https://github.com/krantser/manual_kernel_update.git
```
### **Запуск виртуальной машины через Vagrant и подключение к ней**

Для запуска виртуальной машины необходимо перейти в директорию с файлом Vagrant 
и выполнить команду:

```
cd manual_kernel_update
vagrant up
```
Подключаемся по ssh:

```
vagrant ssh
```

# **Обновление ядра CentOS и установка VBoxGuestAdditions**

Проверяем текущую версию ядра:
```
uname -a
```

Обновляем базу программных пакетов для yum:
```
yum makecache
```

Устанавливаем необходимые пакеты для сборки исходных кодов:
```
sudo yum install ncurses-devel make gcc bc openssl-devel bison \
elfutils-libelf-devel rpm-build wget flex hmaccalc zlib-devel binutils-devel
```

Загружаем архив исходных кодов ядра Linux из ветки с длительной поддержкой 
(longterm):
```
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.36.tar.xz
```

Распаковываем архив и переходим в появившуюся директорию:
```
tar -xf linux-5.4.36.tar.xz
cd linux-5.4.36/
```

Копируем текущую конфигурацию ядра:
```
cp /boot/config-3.10.0-957.12.2.el7.x86_64 .config
```


Компилируем и запускаем меню сборки конфигурации будущего ядра:
```
make menuconfig
```

Сохраняем конфигурацию в `.config`, если мы производили какие-либо манипуляции, 
то настройки конфигурации дополняться.

Теперь компилируем и собираем исходные коды ядра в установочный пакет формата RPM:
```
make rpm-pkg
```

Далее установим новое ядро и перезагрузим систему:
```
sudo rpm -iUv ~/rpmbuild/RPMS/x86_64/*.rpm
sudo reboot
```

Установим дополнения VirtualBox для активации специальных функций, таких 
например как поддержка общих папок между виртуальной машиной и системой хоста. 
Для этого загружаем образ с ПО:
```
wget http://download.virtualbox.org/virtualbox/6.0.20/VBoxGuestAdditions_6.0.20.iso
```

Монтируем полученный образ и переходим в точку (директорию) монтирования:
```
sudo mount -o loop VBoxGuestAdditions_6.0.20.iso /mnt
cd /mnt
```

Устанавливаем дополнения и перезагружаем систему:
```
sudo sh VBoxLinuxAdditions.run --nox11
sudo reboot
```

Далее правим файл Vagrantfile изменив строку:
```
config.vm.synced_folder ".", "/vagrant", disabled: true
```
на
```
config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
```

И перезапускаем виртуальную машину:
```
vagrant reload
```

### **Проверка работоспособности**

После загрузки виртульной машины подключаемся к ней по ssh, как было описано выше
и выполняем команду `uname -a` для того, что бы просмотреть версию текущего ядра
операционной системы. В данном случае вывод будет следующий:
```
Linux kernel-update 5.4.36 #1 SMP Sat May 2 10:22:01 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
```

Далее проверяем работу общих папок с системой хоста, выполняем следующие команды:
```
ls -l /vagrant
```

Вывод команды:
```
total 12
drwxr-xr-x. 1 vagrant vagrant 4096 май  6 20:53 manual
drwxr-xr-x. 1 vagrant vagrant 4096 май  5 10:00 packer
-rw-r--r--. 1 vagrant vagrant 1340 май  2 19:20 Vagrantfile
```
В настройках виртуальной машины текущая её рабочая директория указана как общая
и монтируется внутри машины в `/vagrant`.
Для проверки синхронизации директории можем из системы хоста создать файл в
директории `/home/<username>/manual_kernel_update/` с названием `look_at_me`, 
после чего снова запустить команду `ls -l /vagrant` в виртуальной среде и
получим вывод:
```
-rw-r--r--. 1 vagrant vagrant    0 май  6 21:04 look_at_me
drwxr-xr-x. 1 vagrant vagrant 4096 май  6 20:56 manual
drwxr-xr-x. 1 vagrant vagrant 4096 май  5 10:00 packer
-rw-r--r--. 1 vagrant vagrant 1340 май  2 19:20 Vagrantfile
```
Видим, только что созданный файл и это значит, что поддержка работы общих папок
между хостом и виртуальной машиной работает нормально.


# **Сборка образа ОС с обновлённым ядром и поддержкой функций VBoxGuestAdditions**

Для сборки образа системы воспользуемся `Packer`. Сперва отредактируем файл
конфигурации `centos.json`. В данном случае меняем следующие секции:
```
  "variables": {
    "artifact_description": "CentOS 7.7 with kernel 5.4.36",
    "artifact_version": "7.7.1908",
    "image_name": "centos-7.7"
  }
```

```
      "vboxmanage": [
        [  "modifyvm",  "{{.Name}}",  "--memory",  "2048" ],
        [  "modifyvm",  "{{.Name}}",  "--cpus",  "4" ]
      ]
```

```
  "post-processors": [
    {
      "output": "centos-{{user `artifact_version`}}-k5.4-x86_64.box",
      "compression_level": "7",
      "type": "vagrant"
    }
  ]
```

```
          "scripts" :
            [
              "scripts/os-customise-step-1.sh",
              "scripts/os-customise-step-2.sh",
              "scripts/stage-2-clean.sh"
            ]

```

Далее в директории `packer/script/` создадим сценарии оболочки для автоматизации
установки необходимых пакетов, загрузки, сборки, установки нового ядра и загрузки
и установки VBoxGuestAdditions.
Сценарий первого этапа (os-customise-step-1.sh):
```
#!/bin/bash
yum makecache
sudo yum -y install ncurses-devel make gcc bc openssl-devel bison
sudo yum -y install elfutils-libelf-devel rpm-build wget flex
sudo yum -y install hmaccalc zlib-devel binutils-devel rsync
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.36.tar.xz
tar -xf linux-5.4.36.tar.xz
cp /boot/config-3.10* linux-5.4.36/.config
cd linux-5.4.36/
make olddefconfig
make rpm-pkg
sudo rpm -iUv ~/rpmbuild/RPMS/x86_64/*.rpm
echo ">>>> Step 1 already complete! <<<<"
sudo reboot
```

Сценарий второго этапа (os-customise-step-2.sh):
```
#!/bin/bash
wget http://download.virtualbox.org/virtualbox/6.0.20/VBoxGuestAdditions_6.0.20.iso
sudo mount -o loop VBoxGuestAdditions_6.0.20.iso /mnt
cd /mnt
sudo sh VBoxLinuxAdditions.run --nox11
echo ">>>> Step 2 already complete! <<<<"
```

Сценарий третьего этапа (stage-2-clean.sh):
```
#!/bin/bash

# clean all
yum update -y
yum clean all


# Install vagrant default key
mkdir -pm 700 /home/vagrant/.ssh
curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub \
-o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh


# Remove temporary files
rm -rf /tmp/*
rm  -f /var/log/wtmp /var/log/btmp
rm -rf /var/cache/* /usr/share/doc/*
rm -rf /var/cache/yum
rm -rf /vagrant/home/*.iso
rm  -f ~/.bash_history
history -c

rm -rf /run/log/journal/*

# Fill zeros all empty space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
echo ">>>> Step 3 already complete! <<<<"
#grub2-set-default 1
#echo "###   Hi from secone stage" >> /boot/grub2/grub.cfg
```

Третий скрипт в своей основе взят по умолчанию из примера и лишь закоментированы
последние две строки меняющие настройки загрузчика Grub. После установки нового
ядра система будет по умолчанию загружаться именно с него, поэтому данные настройки
не требуются и команда `grub2-set-default 1` переключает нас на загрузку со 
старым ядром.

После того, как закончен этап работы с конфигурацией и скриптами переходим в 
консоли в папку `packer/`запускаем сборку образа:
```
cd packer/
packer build centos.json
```

### **Тестирование полученного образа системы**

Импортируем новый образ в Vagrant:
```
vagrant box add --name centos-7.7.1908-k5.4-x86_64.box
```

Просмотрим список имеющихся образов:
```
vagrant box list
```

Вывод команды будет следующим:
```
centos-7-kernel-5 (virtualbox, 0)
centos/7          (virtualbox, 1905.1)
```

Перейдём в созданную директорию `/home/<username>/centos-7-kernel-5-test`, создадим
в ней конфигурацию Vagrantfile со следующим содержимым:
```
# Describe VMs
MACHINES = {
  # VM name "kernel update"
  :"kernel-update" => {
              # VM box
              :box_name => "centos-7-kernel-5",
              # VM CPU count
              :cpus => 2,
              # VM RAM size (Mb)
              :memory => 1024,
              # networks
              :net => [],
              # forwarded ports
              :forwarded_port => []
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Disable shared folders
    config.vm.synced_folder ".", "/vagrant", type: 'virtualbox' 
    # Apply VM config
    config.vm.define boxname do |box|
      # Set VM base box and hostname
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxname.to_s
      # Additional network config if present
      if boxconfig.key?(:net)
        boxconfig[:net].each do |ipconf|
          box.vm.network "private_network", ipconf
        end
      end
      # Port-forward config if present
      if boxconfig.key?(:forwarded_port)
        boxconfig[:forwarded_port].each do |port|
          box.vm.network "forwarded_port", port
        end
      end
      # VM resources config
      box.vm.provider "virtualbox" do |v|
        # Set VM RAM size and CPU count
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
    end
  end
end
```
И выполним команду:
```
vagrant init centos-7-kernel-5
```
Запустим виртуальную машину:
```
vagrant up
```

Подключимся по ssh и проверим версию ядра ОС:
```
vagrant ssh
uname -a
```

### **Публикация образа в Vagrant Cloud**

После того, как мы проверили, что запущенная из образа виртуальная машина
работоспособна, можно публиковать данный образ в Vagrant Cloud:
```
vagrant cloud auth login
vagrant cloud publish --release krantser/centos-7-kernel-5 1.0 virtualbox \
manual_kernel_update/packer/centos-7.7.1908-k5.4-x86_64.box 
```

### **Сохраняем все изменения в репозиторий на Github**

Теперь можем сохранить все изменения в репозитории на Github.
Переходим в папку с проектом:
```
cd manual_kernel_update/
```

Просмотрим настройки репозитория:
```
git config --list --show-origin
```

Просмотрим список изменений:
```
git status
```

Добавим файлы для отслеживания:
```
git add Vagrantfile packer/centos.json packer/scripts/stage-2-clean.sh \
packer/scripts/os-customise-step-1.sh packer/scripts/os-customise-step-2.sh 
```

Сделаем коммит (сохраним изменения) и добавим коментарий:
```
git commit -m "Modification and writing of scripts to create OS image is completed."
```

Просмотрим списко коммитов:
```
git log
```

Загрузим зименения на сервер:
```
git push
```
