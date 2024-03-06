#!/bin/ksh
################################################################################
##                                                                            ##
##   [概要]                                                                   ##
##          データベース関連ファイルのバックアップを取得する                  ##
##   [作成/更新履歴]                                                          ##
##        作成者  ：   日立製作所　藤井      2022/10/31 1.0.0                 ##
##   [戻り値]                                                                 ##
##      0 : 正常                                                              ##
##      8 : 異常                                                              ##
##                                                                            ##
##   [パラメータ]                                                             ##
##      なし                                                                  ##
##                                                                            ##
##   [使用方法]                                                               ##
##      /uspg/jp1/zc/shl/exec/ZCZZ_dbcsfilebackup.ksh                         ##
##                                                                            ##
################################################################################
################################################################################
##                                 変数定義                                   ##
################################################################################
L_ShellDir=`/usr/bin/dirname $0`         ## 実行シェルのディレクトリ
L_ShellName=`/bin/basename $0`           ## 実行シェル名

L_CommEnvFile=${L_ShellDir}/ZCZZ_dbcscomn.env ## 共通環境変数ファイル名
L_DBEnvFile=${L_ShellDir}/ZCZZ_dbcsdb.env     ## DB環境設定ファイル名

################################################################################
##                      環境設定環境変数ファイル読み込み                      ##
################################################################################
. ${L_CommEnvFile}
. ${L_DBEnvFile}

################################################################################
##                                 関数定義                                   ##
################################################################################
### ログ出力処理 ###
L_rogushuturyoku() {
    echo `/bin/date "+%Y/%m/%d %H:%M:%S"` ${@}
}

### 終了処理 ###
L_shuryo() {
    ## 作業用フォルダ削除
    if [ -d /tmp/${TE_ZCZZFILE_BACKUP_BASE} ]; then
        rm -fr /tmp/${TE_ZCZZFILE_BACKUP_BASE}
    fi
    L_modorichi=${1:-0}
    # L_rogushuturyoku "[Info] ${L_ShellName} 終了  END_CD="${L_modorichi}
    L_rogushuturyoku "[Info] ${L_ShellName} Ended.  END_CD="${L_modorichi}
    exit ${L_modorichi}
}

### trap 処理 ###
trap 'L_shuryo 8' 1 2 3 15

################################################################################
##                                 メイン                                     ##
################################################################################
### 処理開始出力 ###
# L_rogushuturyoku "[Info] ${L_ShellName} 開始"
L_rogushuturyoku "[Info] ${L_ShellName} Start."

### 実行ユーザ確認
if [ `whoami` != "oracle" ]; then
#    L_rogushuturyoku "[Error] 実行権限がありません。oracleユーザで実行してください."
    L_rogushuturyoku "[Error] It cannot be executed because there is no authority. Please run with the oracle user."
    L_shuryo ${TE_ZCZZERROR}
fi

### バックアップ開始 ###
# L_rogushuturyoku "[Info] データベース関連ファイルバックアップ 開始"
L_rogushuturyoku "[Info] Database-related file backup process is started."

# 作業用フォルダ作成
mkdir -p /tmp/${TE_ZCZZFILE_BACKUP_BASE}
mkdir -p /tmp/${TE_ZCZZFILE_BACKUP_BASE}/wallet_root
mkdir -p /tmp/${TE_ZCZZFILE_BACKUP_BASE}/pfile
mkdir -p /tmp/${TE_ZCZZFILE_BACKUP_BASE}/odbcs
mkdir -p /tmp/${TE_ZCZZFILE_BACKUP_BASE}/passwd
mkdir -p /tmp/${TE_ZCZZFILE_BACKUP_BASE}/network
chmod -R 775 /tmp/${TE_ZCZZFILE_BACKUP_BASE}

# 透過的暗号化(TDE)用マスター暗号鍵
cp -r ${TE_ZCZZDB_WALLET_ROOT}/* /tmp/${TE_ZCZZFILE_BACKUP_BASE}/wallet_root
L_RC=$?
if [ $L_RC -ne 0 ]; then
#     L_rogushuturyoku "[Error] ファイルのコピーに失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Failed to copy the file. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

# 初期化パラメータファイル(テキスト)生成
$ORACLE_HOME/bin/sqlplus -L -S / as sysdba <<EOF
whenever oserror exit failure
whenever sqlerror exit failure
startup mount
create pfile='/tmp/${TE_ZCZZFILE_BACKUP_BASE}/pfile/${ORACLE_UNQNAME}.ora' from spfile;
whenever sqlerror continue
shutdown immediate
exit
EOF

L_RC=$?
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] 初期化パラメータファイルの作成に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Failed to create the initialization parameter file. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

# パスワードファイル
L_PWFILEENV=`srvctl config database -db ${ORACLE_UNQNAME} | grep "Password file:"`
L_PWDFILE=`echo ${L_PWFILEENV} | cut -d ':' -f 2 | sed 's/^[[:blank:]]*//'`
if [ "${L_PWDFILE}" != "" ]; then
    asmcmd --privilege sysdba --inst ${TE_ZCZZASM_INSTANCE_NAME} pwcopy ${L_PWDFILE} /tmp/${TE_ZCZZFILE_BACKUP_BASE}/passwd/orapw${ORACLE_SID}
    L_RC=$?
    if [ $L_RC -ne 0 ]; then
        # L_rogushuturyoku "[Error] パスワードファイルの取得に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
        L_rogushuturyoku "[Error] Failed to get the password file. HOST=${TE_ZCZZHOSTNAME}"
        L_shuryo ${TE_ZCZZERROR}
    fi
else
    cp $ORACLE_HOME/dbs/orapw${ORACLE_SID} /tmp/${TE_FILE_BACKUP_BASE}/passwd
    L_RC=$?
    if [ $L_RC -ne 0 ]; then
        # L_rogushuturyoku "[Error] ファイルのコピーに失敗しました。HOST=${TE_ZCZZHOSTNAME}"
        L_rogushuturyoku "[Error] Failed to copy the file. HOST=${TE_ZCZZHOSTNAME}"
        L_shuryo ${TE_ZCZZERROR}
    fi
fi


# Oracle Net Service Configuration File Backup
cp $ORACLE_HOME/network/admin/*.ora /tmp/${TE_ZCZZFILE_BACKUP_BASE}/network
L_RC=$?
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] ファイルのコピーに失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Failed to copy the file. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

# SBT Library Backup
cp -r $HOME/.odbcs/* /tmp/${TE_ZCZZFILE_BACKUP_BASE}/odbcs
L_RC=$?
if [ $L_RC -ne 0 ]; then
    L_rogushuturyoku "[Error] ファイルのコピーに失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

# zipファイル化
L_dir=`pwd`
cd /tmp
zip /tmp/${TE_ZCZZFILE_BACKUP_BASE}.zip -r ${TE_ZCZZFILE_BACKUP_BASE}
unzip -l /tmp/${TE_ZCZZFILE_BACKUP_BASE}.zip
L_RC=$?
cd ${L_dir}
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] ZIPファイルの作成に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Failed to create ZIP file.HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

# オブジェクトストレージに登録
# L_rogushuturyoku "[Info] ファイルバックアップをオブジェクトストレージに登録します。"
# L_rogushuturyoku "[Info] ファイル=/tmp/${TE_FILE_BACKUP_BASE}.zip"
L_rogushuturyoku "[Info] Register a file backup to object storage."
L_rogushuturyoku "[Info] flie=/tmp/${TE_ZCZZFILE_BACKUP_BASE}.zip"
oci os object put \
    -ns ${TE_ZCZZOS_NAMESPACENAME} \
    -bn ${TE_ZCZZOS_BUCKETNAME} \
    --name file_backup/${TE_ZCZZFILE_BACKUP_BASE}.zip \
    --file /tmp/${TE_ZCZZFILE_BACKUP_BASE}.zip \
    --output table
L_RC=$?
if [ $L_RC -ne 0 ]; then
    # L_rogushuturyoku "[Error] ファイルの登録に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Failed to register the file. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
else
    # L_rogushuturyoku "[Info] ファイルバックアップをオブジェクトストレージに登録しました。"
    L_rogushuturyoku "[Info] A file backup has been registered in the object storage."
fi

# OCI Command execute to get File Backup List
L_RESULTLIST=`oci os object list \
                  -bn ${TE_ZCZZOS_BUCKETNAME} \
                  -ns ${TE_ZCZZOS_NAMESPACENAME} \
                  --prefix file_backup/Itoen_FileBackup_${TE_ZCZZHOSTNAME} \
                  --output table`
L_RC=$?
if [ $L_RC -ne 0 ]; then
#     L_rogushuturyoku "[Error] ファイル一覧の取得に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
    L_rogushuturyoku "[Error] Failed to get the file list. HOST=${TE_ZCZZHOSTNAME}"
    L_shuryo ${TE_ZCZZERROR}
fi

# File Backup List Creation
L_FNAMEARRAY=()
L_cnt=0
for line in ${L_RESULTLIST}
do
    L_FNAME=`echo ${line} | grep file_backup | cut -d '|' -f 5`
    if [ "${L_FNAME}" != "" ]; then
        L_FNAMEARRAY[$L_cnt]="${L_FNAME}"
        L_cnt=$(expr ${L_cnt}+1)
    fi
done

# Reverse Sort File Backup List 
L_FNAMEARRAY=(`for item in "${L_FNAMEARRAY[@]}"; do echo "$item"; done | sort -r`)

L_cnt=0
for fname in ${L_FNAMEARRAY[@]}
do
    if [ $L_cnt -gt 1 ]; then
        oci os object delete \
            -bn ${TE_ZCZZOS_BUCKETNAME} \
            -ns ${TE_ZCZZOS_NAMESPACENAME} \
            --name $fname --force
       if [ $L_RC -ne 0 ]; then
           # L_rogushuturyoku "[Error] ファイル一覧の取得に失敗しました。HOST=${TE_ZCZZHOSTNAME}"
           L_rogushuturyoku "[Error] Failed to get the file list. HOST=${TE_ZCZZHOSTNAME}"
           L_shuryo ${TE_ZCZZERROR}
        fi
        echo "[Info] File deleted. File Name : $fname"
    else
        echo "[Info] Skip delete. File Name : $fname"
    fi
    L_cnt=$(expr ${L_cnt}+1)
done

# L_rogushuturyoku "[Info] データベース関連ファイルバックアップ 終了"
L_rogushuturyoku "[Info] Database-related file backup process is started."

### 処理終了出力 ###
L_shuryo ${TE_ZCZZSUCCESS}
