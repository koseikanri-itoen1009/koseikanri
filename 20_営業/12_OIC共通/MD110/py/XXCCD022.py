"""
--------------------------------------------------------------------------------

     [概要]
        ESSジョブ用OIC統合処理のREST APIを起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2022/10/31 Draft1A
          更新履歴：   SCSK   吉岡           2022/10/31 Draft1A  初版
                       SCSK   久保田         2023/02/22 Issue1.0 Issue化
                       SCSK   吉岡           2023/04/12 Issue1.1 ST0102対応

     [戻り値]
        0 : 正常
        4 : 警告
        8 : 異常

     [パラメータ]
        ファイルパス                         string
        パラメータ作成処理API                string
        ESSジョブパラメータJSONファイル名    string

     [使用方法]
        /u02/pv/XXCCD022.py

--------------------------------------------------------------------------------
"""

import sys
import json
import requests
import time
import os
import zipfile
import traceback
import re
import ast

from com.Xxccdcomn import Xxccdcomn
from com.PyComnException import PyComnException

def execApi(com, execPayload, exeName, apiUrl):

    ## RESTAPI実行
    apiResponse = requests.request("POST"
        , com.getEnvValue("OIC_HOST") + apiUrl
        , headers=com.headers
        , data=execPayload)

    ## RESTAPIエラー判定
    com.oicErrChk(apiResponse, exeName)

    ## リターンコードエラー判定
    rtnRes = com.oicRtnCdChk(apiResponse, exeName)

    return rtnRes

def execEssJob(com, essJobJsonList, paramList):

    for essJobJson in essJobJsonList:
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "jobPackage"     : essJobJson["jobPackage"],
            "jobName"        : essJobJson["jobName"],
            "singleJobParam" : paramList if paramList else essJobJson["singleJobParam"],
            "jobSetFlag"     : "N"
        })
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["ESSジョブ実行API_" + essJobJson["jobName"]]
            , "/ic/api/integration/v1/flows/rest/XXCCD018/1.0/RestESSJob")

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["ESSジョブ実行API_" + essJobJson["jobName"]])

        ##### 共通 #####
        parentId = apiResponse["processId"]
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "processId" : apiResponse["processId"]
        })

        ##### コールバックチェック #####
        loopCnt = 0
        while True:
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["コールバックチェック処理API_ESSジョブ実行_" + essJobJson["jobName"]]
                , "/ic/api/integration/v1/flows/rest/XXCCD011/1.0/RestCallBackCheck")
            loopCnt += 1

            if apiResponse["JobStatusCount"] > 0:
                ## 実行回数判定
                if loopCnt >= int(com.getEnvConstValue("MAX_LOOP_CNT")):
                    com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                    raise PyComnException("CCDE0005", ["コールバックチェック処理API_ESSジョブ実行_" + essJobJson["jobName"]])
                ## 待機
                time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))
                continue
            else:
                break

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["コールバックチェック処理API_ESSジョブ実行_" + essJobJson["jobName"]])

        ##### 実行結果出力 #####
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["実行結果出力API_ESSジョブ実行_" + essJobJson["jobName"]]
            , "/ic/api/integration/v1/flows/rest/XXCCD012/1.0/RestOutputFile")

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["実行結果出力API_ESSジョブ実行_" + essJobJson["jobName"]])

        ##### ESSジョブチェック実行 #####
        execSubEssJob(com, parentId, parentId)

        ##### ジョブステータスチェック #####
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["ジョブステータスチェックAPI_ESSジョブ実行_" + essJobJson["jobName"]]
            , "/ic/api/integration/v1/flows/rest/XXCCD013/1.0/RestJobStatusCheck")

        ## ジョブステータスコード判定
        jobStCd = apiResponse["JobStatusCode"]
        if jobStCd == com.getEnvConstValue("JOBST_WARN_CD"):
            com.endCd = com.getEnvConstValue("JP1_WARN_CD")
            com.writeMsg("CCPW0001", [])
        elif jobStCd == com.getEnvConstValue("JOBST_ERR_CD"):
            com.endCd = com.getEnvConstValue("JP1_ERR_CD")
            raise PyComnException("CCDE0004", [])

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["ジョブステータスチェックAPI_ESSジョブ実行_" + essJobJson["jobName"]])

def execSubEssJob(com, processId, parentId):
    try:
        ## 読み込み対象の出力結果ファイル、logファイル名を生成
        zipFileName = str(processId) + "_outputFiles.zip"

        ## プロセスID取得用に検出パターンJSONファイルデータをリスト型変換
        ptnFile = open(com.getEnvValue("COM_PATH") + "XXCCDPTN.json", "r")
        fileDate = ptnFile.read()
        ptnFile.close()
        ptnList = [ptn for ptn in ast.literal_eval(fileDate) if 'PTNGP001' in ptn]

        ## 実行結果出力ファイルの読み込みを行う。
        with zipfile.ZipFile(com.getEnvValue("ZIP_FILE_PATH") + zipFileName, 'r') as zip_data:
            ## zipファイル内からファイルリストを取得
            infos = zip_data.infolist()
            for info in infos:
                ## logファイル以外の場合はスキップ
                re_match = re.compile(r'^.*?\.log$').match
                if re_match(info.filename) is None:
                    continue

                ## 指定のlogファイルデータを取得
                logData = zip_data.read(info.filename).decode('utf-8')
                logDataList = logData.splitlines()

                for (lData) in logDataList:
                    ## 検出パターンデータにてlogファイルデータを検索し、プロセスIDを取得
                    pid = 0
                    for ptnStr in ptnList:
                        result = re.findall(ptnStr['PTNGP001'], lData)
                        if len(result) > 0:
                            pid = int(result[0])
                            break

                    ## プロセスIDが取得できた場合、取得したプロセスIDにてESSジョブチェック実行
                    if pid > 0:
                        ## ESSジョブチェック実行
                        execEssJobCk(com, pid, parentId)

                        ## 取得したプロセスIDのESSジョブチェックを実行
                        execSubEssJob(com, pid, parentId)

    except zipfile.BadZipFile as e:
        com.endCd = com.getEnvConstValue("JP1_ERR_CD")
        raise PyComnException("CCDE0008", [processId, traceback.format_exc()])

def execEssJobCk(com, processId, parentId):

        ## 入力パラメータ生成
        execPayload = json.dumps({
            "processId" : processId
           ,"parentId" : processId
        })

        ##### ESSジョブチェックAPI #####
        loopCnt = 0
        while True:
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["ESSジョブチェック_" + str(parentId) + ":" + str(processId)]
                , "/ic/api/integration/v1/flows/rest/XXCCD030/1.0/RestEssJobCheck")
            loopCnt += 1

            if apiResponse["JobFinishStatus"] != "0":
                ## 実行回数判定
                if loopCnt >= int(com.getEnvConstValue("MAX_LOOP_CNT_JOBCK")):
                    com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                    raise PyComnException("CCDE0005", ["ESSジョブチェック_" + str(parentId) + ":" + str(processId)])
                ## 待機
                time.sleep(int(com.getEnvConstValue("SLEEP_TIME_JOBCK")))
                continue
            else:
                break

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["ESSジョブチェック_" + str(parentId) + ":" + str(processId)])

        ## 入力パラメータ生成
        execPayload = json.dumps({
            "processId" : processId
        })

        ##### 実行結果出力 #####
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["実行結果出力API_ESSジョブチェック_" + str(parentId) + ":" + str(processId)]
            , "/ic/api/integration/v1/flows/rest/XXCCD012/1.0/RestOutputFile")

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["実行結果出力API_ESSジョブチェック_" + str(parentId) + ":" + str(processId)])

### Main処理 ###
def main():
    ## 共通処理インスタンス生成
    args = sys.argv
    com = Xxccdcomn("XXCCD022", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        filePath = com.paramChkAndConv("ファイルパス", args[1], True, "str", 0)
        creParamApi = com.paramChkAndConv("パラメータ作成処理API", args[2], False, "str", 0)
        essJobParamJsonFileName = com.paramChkAndConv("ESSジョブパラメータJSONファイル名", args[3], False, "str", 0)

        ##### 0バイトファイル削除処理 #####
        if com.delZeroByteFileExec(filePath):
            raise PyComnException("CCDI0005", [])

        ## パラメータ.パラメータ作成処理APIが設定されている場合
        if creParamApi: 
            ##### パラメータ作成処理 #####
            ## 入力パラメータ生成
            execPayload = json.dumps({
                "filePath" : filePath
            })
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["パラメータ作成処理API"], creParamApi)

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["パラメータ作成処理API"])
        else:
            apiResponse = {
                "singleJobParam" : ""
            }

        ## ESSジョブ実行判定
        if essJobParamJsonFileName: 
            if not com.isZeroByteFileChk(essJobParamJsonFileName):
                ## パラメータ.ESSジョブパラメータJSONファイルデータのリスト型変換
                f = open(essJobParamJsonFileName, 'r')
                fileDate = f.read()
                f.close()
                essJobJsonList = com.paramChkAndConv("ESSジョブパラメータJSONファイルデータ", fileDate, True, "list", 0)

                ##### ESSジョブ実行 #####
                execEssJob(com, essJobJsonList, apiResponse["singleJobParam"])

    ## 例外判定
    except PyComnException as e1:
      com.writeMsg(e1.msgId, e1.repStr)

    except Exception as e:
      com.logging.exception(e)
      com.endCd = com.getEnvConstValue("JP1_ERR_CD")

    finally:
      ## 終了処理
      return com.endExec()

if __name__ == "__main__":
    ## Main実行
    sys.exit(int(main()))
