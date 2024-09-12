"""
--------------------------------------------------------------------------------

     [概要]
        Export用のREST APIを起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2023/04/19 Issue1.2
          更新履歴：   SCSK   吉岡           2022/07/07 Draft1A  初版
                       SCSK   吉岡           2022/10/31 Draft1B  仕様変更対応
                                             2023/02/27 Issue1.1 BIP出力のタイアウトエラー対応
                                             2023/04/19 Issue1.2 データ変換非同期対応
                       SCSK   細沼           2024/09/09 Issue1.3 障害対応：E_本稼動_20182

     [戻り値]
        0 : 正常
        4 : 警告
        8 : 異常

     [パラメータ]
        BIP名                                string
        パラメータリスト                     string
        パラメータ作成処理API                string
        データ変換処理API                    string
        データ変換非同期フラグ               string

     [使用方法]
        /u02/pv/XXCCD015.py

--------------------------------------------------------------------------------
"""

import sys
import json
import requests
import time
import os

from com.Xxccdcomn import Xxccdcomn
from com.PyComnException import PyComnException

def execApi(com, execPayload, exeName, apiUrl, isExecFunk=True):

    ## サーバーエラーを考慮したREST API呼出し
    for cnt in range(int(com.getEnvConstValue("MAX_LOOP_CNT_REST_RETRY"))):
        
        if cnt > 0 :
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

        rtnRes = None
        if isExecFunk:
            ## リターンコードエラー判定
            rtnRes = com.oicRtnCdChk(apiResponse, exeName)

        return rtnRes

    else:
        ## REST API呼出しのリトライ回数が上限に達した場合のエラー処理
        com.endCd = com.getEnvConstValue("JP1_ERR_CD")
        raise PyComnException("CCDE0011", exeName)

### Main処理 ###
def main():
    ## 共通処理インスタンス生成
    args = sys.argv
    com = Xxccdcomn("XXCCD015", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        bipName = com.paramChkAndConv("BIP名", args[1], True, "str", 0)
        paramList = com.paramChkAndConv("パラメータリスト", args[2], False, "str", 0)
        creParamApi = com.paramChkAndConv("パラメータ作成処理API", args[3], False, "str", 0)
        convDataApi = com.paramChkAndConv("データ変換処理API", args[4], True, "str", 0)

        asynDataConvFlg = "0"
        if len(args) > 5:
            asynDataConvFlg = args[5]

        ## パラメータ.パラメータ作成処理APIが設定されている場合
        if creParamApi: 
            ##### パラメータ作成処理 #####
            ## 入力パラメータ生成
            execPayload = json.dumps({
                "paramList" : paramList
            })
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["パラメータ作成処理API"], creParamApi)

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["パラメータ作成処理API"])
        else:
            apiResponse = {
                "BIPParamList" : paramList
            }

        ##### BIP実行 #####
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "BIPParam" : apiResponse["BIPParamList"],
            "BIPName"  : bipName
        })
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["BIP実行API"]
            , "/ic/api/integration/v1/flows/rest/XXCCD006/1.0/RestBIP")

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["BIP実行API"])
	
        ##### 共通 #####
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "processId" : apiResponse["processId"]
        })

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

        if asynDataConvFlg != "1":
            ##### データ変換処理 #####
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["データ変換処理API"], convDataApi)

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["データ変換処理API"])

        else:
            ##### データ変換処理 #####
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["データ変換処理API_非同期"], convDataApi, False)

            ## 実行初回待機
            time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["データ変換処理API_非同期"])

            ##### 非同期処理チェック #####
            loopCnt = 0
            while True:
                ## RESTAPI実行、エラー判定
                apiResponse = execApi(com, execPayload, ["非同期処理チェックAPI"]
                    , "/ic/api/integration/v1/flows/rest/XXCCD036/1.0/RestAsyncCheck")
                loopCnt += 1

                if apiResponse["JobStatusCount"] == 1:
                    ## 実行回数判定
                    if loopCnt >= int(com.getEnvConstValue("MAX_LOOP_CNT")):
                        com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                        raise PyComnException("CCDE0005", ["非同期処理チェックAPI"])
                    ## 待機
                    time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))
                    continue
                else:
                    ## エラー詳細設定の場合はエラー処理
                    if apiResponse["errorDetail"]:
                        ####エラー処理
                        com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                        raise PyComnException("CCDE0009", [apiResponse["errorDetail"]])
                    break

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["非同期処理チェックAPI"])

        ##### Outbound用実行結果出力 #####
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["実行結果出力API"]
            , "/ic/api/integration/v1/flows/rest/XXCCD026/1.0/RestOutputFile")

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
