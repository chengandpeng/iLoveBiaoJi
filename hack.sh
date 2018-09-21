#!/bin/bash

############
#  2018.9.20 by CP
#  防微信和QQ被公司直接干掉的自动化脚本
############

## 常量定义
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'
CRT_NAME='ILOVEBIAOJI'
CHECK_CER_EXIST=$(security find-identity -v -p codesigning | grep ${CRT_NAME})
REP_TAG='abc'

###
# 证书创建导入 
###
function create_certificate() {
    if [ ! -z "$CHECK_CER_EXIST" ]; then
        echo -e "${GREEN}证书已经存在,可以直接破解${RESET}"
        exit 0
    fi

    echo -e "${GREEN}***开始创建并导入证书***${RESET}"
    echo -e "${GREEN}步骤1:生成证书...${RESET}"
    if [ ! -f ./apple.key ]; then
        openssl genrsa -out apple.key 2048
    fi

    echo -e "${GREEN}步骤2:请输入任意密码并记住...${RESET}"
    openssl req -x509 -new -config crt.conf -nodes -key apple.key -extensions extensions -sha256 -out apple.crt
    openssl pkcs12 -export -inkey apple.key -in apple.crt -out apple.p12

    if [ $? -ne 0 ]; then
        echo -e "${RED}生成失败,重新来过${RESET}"
        exit
    fi

    echo -e "${GREEN}步骤4:请输入刚才的密码,导入P12证书,并手动信任${CRT_NAME}证书...完成后再次执行脚本进行破解${RESET}"
    # security import ./apple.p12 -k $HOME/Library/Keychains/login.keychain-db
    open ./apple.p12
}

###
# 破解
###
function crack_app() {
    APP_NAME=$1
    # 检查证书是否存在
    if [ -z "$CHECK_CER_EXIST" ]; then
        echo -e "${RED}自签证书不存在,请先完成第一步${RESET}"
        exit 1
    fi

    echo -e "${GREEN}指定${APP_NAME}.app路径:回车使用默认路径Applications,或者将App拖入终端得到路径后回车"
    read path

    if [ -z $path ]; then
        APP_PATH=/Applications/${APP_NAME}.app
    else
        APP_PATH=$path
    fi
    # 检查应用是否存在
    if [ ! -d $APP_PATH ]; then
        echo -e "${RED}${APP_PATH}不存在,请先将应用加进去${RESET}"
        exit 1
    fi

    # 替换字符
    mv ${APP_PATH}/Contents/MacOS/* ${APP_PATH}/Contents/MacOS/${REP_TAG}
    sed -i -e "s/>$APP_NAME</>$REP_TAG</g" ${APP_PATH}/Contents/Info.plist
    rm ${APP_PATH}/Contents/Info.plist-e
    codesign -f -s $CRT_NAME ${APP_PATH}

    if [ $? -ne 0 ]; then
        echo -e "${RED}破解失败${RESET}"
    else
        echo -e "${GREEN}搞定,去打开试试吧${RESET}"
    fi
} 

###
# Main
###
echo -e "${GREEN}***标机使用微信,QQ脚本***"
echo -e "请先自行从官网下载微信和QQ${RESET}"
echo -e "1: 生成导入自签证书，如果已经完成，不需重复执行"
echo -e "2: 破解微信"
echo -e "3: 破解QQ"
echo -e "${GREEN}***请输入数字执行命令:***${RESET}"

read type
if [ $type -eq 1 ]; then
    create_certificate
elif [ $type -eq 2 ]; then
    crack_app "WeChat"
elif [ $type -eq 3 ]; then
    crack_app "QQ"
else
    echo -s "走你!"
    exit 1
fi

