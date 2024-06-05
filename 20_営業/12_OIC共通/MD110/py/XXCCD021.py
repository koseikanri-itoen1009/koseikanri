"""
--------------------------------------------------------------------------------

     [概要]
        HDL用OIC統合処理のREST APIを起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2022/10/31 Draft1B
          更新履歴：   SCSK   吉岡           2022/08/05 Draft1A  初版
                       SCSK   吉岡           2022/10/31 Draft1B  仕様変更対応
                       SCSK   久保田         2023/02/22 Issue1.0 Issue化
                       SCSK   細沼           2024/04/02 Issue1.1 障害対応：E_本稼動_19878 502bad gatewayエラー対応

     [戻り値]
        0 : 正常
        4 : 警告
        8 : 異常

     [パラメータ]
        ファイルパス                         string
        データ変換処理API                    string
        ESSジョブパラメータJSONファイル名    string

     [使用方法]
        /u02/pv/XXCCD021.py

--------------------------------------------------------------------------------
"""

import sys
import json
import requests
import time
import os

from com.Xxccdcomn import Xxccdcomn
from com.PyComnException import PyComnException

def execApi(com, execPayload, exeName, apiUrl):

    ## サーバーエラーを考慮したREST API呼出し
    for cnt in range(int(com.getEnvConstValue("MAX_LOOP_CNT_REST_RETRY"))):
        
        if cnt > 0:
            #初回以外は規定の秒数待機後、RESTAPIを実行
            time.sleep(int(com.getEnvConstValue("SLEEP_TIME_REST_RETRY")))

        ## RESTAPI実行
        apiResponse = requests.request("POST"
            , com.getEnvValue("OIC_HOST") + apiUrl
            , headers=com.headers
            , data=execPayload)

        ## RESTAPI サーバーエラー判定
        if com.oicErrChkSrv(apiResponse) :
            ## サーバーエラーが発生した場合、RESTAPI呼出しを再試行
            continue

        ## RESTAPIエラー判定
        com.oicErrChk(apiResponse, exeName)

        ## リターンコードエラー判定
        rtnRes = com.oicRtnCdChk(apiResponse, exeName)

        return rtnRes

    else:
        ## REST API呼出しのリトライ回数が上限に達した場合のエラー処理
        com.endCd = com.getEnvConstValue("JP1_ERR_CD")
        raise PyComnException("CCDE0011", exeName)

def execEssJob(com, essJobJsonList):

    for essJobJson in essJobJsonList:
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "jobPackage"     : essJobJson["jobPackage"],
            "jobName"        : essJobJson["jobName"],
            "singleJobParam" : essJobJson["singleJobParam"],
            "jobSetFlag"     : "N"
        })
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["ESSジョブ実行API_" + essJobJson["jobName"]]
            , "/ic/api/integration/v1/flows/rest/XXCCD018/1.0/RestESSJob")

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["ESSジョブ実行API_" + essJobJson["jobName"]])

        ##### 共通 #####
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

### Main処理 ###
def main():
    ## 共通処理インスタンス生成
    args = sys.argv
    com = Xxccdcomn("XXCCD021", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        filePath = com.paramChkAndConv("ファイルパス", args[1], True, "str", 0)
        convDataApi = com.paramChkAndConv("データ変換処理API", args[2], True, "str", 0)
        essJobParamJsonFileName = com.paramChkAndConv("ESSジョブパラメータJSONファイル名", args[3], False, "str", 0)

        ##### 0バイトファイル削除処理 #####
        if com.delZeroByteFileExec(filePath):
            raise PyComnException("CCDI0005", [])

        ##### データ変換処理 #####
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "filePath" : filePath
        })
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["データ変換処理API"], convDataApi)

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["データ変換処理API"])

        ##### HDL実行 #####
        hdlFullpathFile = apiResponse["hdlFullpathFile"]
        
        ## ファイル存在チェック
        if not os.path.isfile(hdlFullpathFile):
            raise PyComnException("CCDI0004", [])

        ## 入力パラメータ生成
        execPayload = json.dumps({
            "filePath" : os.path.dirname(hdlFullpathFile),
            "fileName" : os.path.basename(hdlFullpathFile)
        })

        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["HDL実行API"]
            , "/ic/api/integration/v1/flows/rest/XXCCD008/1.0/RestHDL")

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["HDL実行API"])

        ##### 共通 #####
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "processId" : apiResponse["processId"]
        })

        ##### HDLステータスチェック #####
        loopCnt = 0
        while True:
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["HDLステータスチェックAPI"]
                , "/ic/api/integration/v1/flows/rest/XXCCD017/1.0/RestHDLStatusCheck")
            loopCnt += 1

            if apiResponse["HDLStatus"] == com.getEnvConstValue("HDLST_SUCC_CD"):
                break
            elif (apiResponse["HDLStatus"] == com.getEnvConstValue("HDLST_WARN_CD")
              or apiResponse["HDLStatus"] == com.getEnvConstValue("HDLST_ERR_CD")):
                com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                raise PyComnException("CCDE0007", [])
            else:
                ## 実行回数判定
                if loopCnt >= int(com.getEnvConstValue("MAX_LOOP_CNT")):
                    com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                    raise PyComnException("CCDE0005", ["HDLステータスチェック処理API"])
                ## 待機
                time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))
                continue

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["HDLステータスチェックAPI"])

        ## ESSジョブ実行判定
        if essJobParamJsonFileName: 
            if not com.isZeroByteFileChk(essJobParamJsonFileName):
                ## パラメータ.ESSジョブパラメータJSONファイルデータのリスト型変換
                f = open(essJobParamJsonFileName, 'r')
                fileDate = f.read()
                f.close()
                essJobJsonList = com.paramChkAndConv("ESSジョブパラメータJSONファイルデータ", fileDate, True, "list", 0)

                ##### ESSジョブ実行 #####
                execEssJob(com, essJobJsonList)

        ##### コールバックチェック #####
        loopCnt = 0
        while True:
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["コールバックチェック処理API"]
                , "/ic/api/integration/v1/flows/rest/XXCCD011/1.0/RestCallBackCheck")
            loopCnt += 1

            if apiResponse["JobStatusCount"] > 0:
                ## 実行回数判定
                if loopCnt >= int(com.getEnvConstValue("MAX_LOOP_CNT")):
                    com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                    raise PyComnException("CCDE0005", ["コールバックチェック処理API"])
                ## 待機
                time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))
                continue
            else:
                break

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["コールバックチェック処理API"])

        ##### 実行結果出力 #####
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["実行結果出力API"]
            , "/ic/api/integration/v1/flows/rest/XXCCD012/1.0/RestOutputFile")

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["実行結果出力API"])

        ##### ジョブステータスチェック #####
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["ジョブステータスチェックAPI"]
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
        com.writeMsg("CCDI0002", ["ジョブステータスチェックAPI"])

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
