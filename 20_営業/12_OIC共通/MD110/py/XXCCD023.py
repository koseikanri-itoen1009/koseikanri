"""
--------------------------------------------------------------------------------

     [概要]
        入力パラメータで指定されたOIC統合をREST APIにて起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2022/10/31 Draft1A
          更新履歴：   SCSK   吉岡           2022/10/31 Draft1A  初版
                       SCSK   久保田         2023/02/22 Issue1.0 Issue化
                       SCSK   細沼           2023/07/24 Issue1.1 E_本稼動_19390対応
                       SCSK   細沼           2024/04/02 Issue1.2 障害対応：E_本稼動_19878 502bad gatewayエラー対応

     [戻り値]
        0 : 正常
        4 : 警告
        8 : 異常

     [パラメータ]
        ファイルパス                         string
        データ変換処理API                    string
        データ変換非同期フラグ               string

     [使用方法]
        /u02/pv/XXCCD023.py

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
    com = Xxccdcomn("XXCCD023", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        filePath = com.paramChkAndConv("ファイルパス", args[1], True, "str", 0)
        convDataApi = com.paramChkAndConv("データ変換処理API", args[2], True, "str", 0)

        asynDataConvFlg = "0"
        if len(args) > 3:
            asynDataConvFlg = args[3]

        ##### 0バイトファイル削除処理 #####
        com.delZeroByteFileExec(filePath)

        if asynDataConvFlg != "1":
            ##### データ変換処理 #####
            ## 入力パラメータ生成
            execPayload = json.dumps({
                "filePath" : filePath
            })

            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["データ変換処理API"], convDataApi)

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["データ変換処理API"])

        else:
            ##### データ変換処理 #####
            ## 入力パラメータ生成
            execPayload = json.dumps({})

            ## 非同期ID採番処理 ##
            apiResponse = execApi(com, execPayload, ["非同期ID採番処理API"]
            , "/ic/api/integration/v1/flows/rest/XXCCD037/1.0/RestGetAsyncId", True)
            
            asyncId = apiResponse["asyncId"]
            
            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["非同期ID採番処理API"])

            ## 入力パラメータ生成
            execPayload = json.dumps({
                "filePath" : filePath,
                "asyncId" : asyncId,
                "idType" : "A"
            })

            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["データ変換処理API_非同期"], convDataApi, False)

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["データ変換処理API_非同期"])

            ## 実行初回待機
            time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))

            ##### 非同期処理チェック #####
            ## 入力パラメータ生成
            execPayload = json.dumps({
                "processId" : asyncId,
                "idType" : "A"
            })
            
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
