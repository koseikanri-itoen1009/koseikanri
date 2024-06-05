"""
--------------------------------------------------------------------------------

     [概要]
        Import用OIC統合処理のREST APIを起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2023/04/28 Issue1.2
          更新履歴：   SCSK   吉岡           2022/07/04 Draft1A  初版
                       SCSK   吉岡           2022/10/31 Draft1B  仕様変更対応
                       SCSK   吉岡           2023/03/01 Issue1.1 10MB超えの抽出ファイル対応
                       SCSK   吉岡           2023/04/28 Issue1.2 ESSジョブ階層取得対応
                       SCSK   細沼           2023/07/26 Issue1.3 障害対応：E_本稼動_19362
                       SCSK   細沼           2023/09/29 Issue1.4 障害対応：E_本稼動_19531
                       SCSK   細沼           2024/04/02 Issue1.5 障害対応：E_本稼動_19878 502bad gatewayエラー対応

     [戻り値]
        0 : 正常
        4 : 警告
        8 : 異常

     [パラメータ]
        FBDI名                               string
        ファイルパス                         string
        データ変換処理API                    string

     [使用方法]
        /u02/pv/XXCCD016.py

--------------------------------------------------------------------------------
"""

import sys
import json
import requests
import time
import glob
import os
import asyncio
import functools

from com.Xxccdcomn import Xxccdcomn
from com.PyComnException import PyComnException
from requests.exceptions import ConnectTimeout

def execApi(com, execPayload, exeName, apiUrl, isExecFunk=True):

    try:
        ## サーバーエラーを考慮したREST API呼出し
        for cnt in range(int(com.getEnvConstValue("MAX_LOOP_CNT_REST_RETRY"))):
            
            if cnt > 0 :
                #初回以外は規定の秒数待機後、RESTAPIを実行
                time.sleep(int(com.getEnvConstValue("SLEEP_TIME_REST_RETRY")))
            
            ## RESTAPI実行
            apiResponse = requests.request("POST"
                , com.getEnvValue("OIC_HOST") + apiUrl
                , headers=com.headers
                , data=execPayload
                , timeout=(float(com.getEnvConstValue("REST_CONN_TIMEOUT_SEC")), None))
                
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

    ## 例外判定
    except ConnectTimeout as e:
        com.endCd = com.getEnvConstValue("JP1_ERR_CD")
        
        callName = ""
        if len(exeName) > 0:
            callName = exeName[0]
        else:
            callName = exeName
            
        raise PyComnException("CCDE0010", [callName, str(e)])

async def paraExecCallBackApi(com, pram):
    loop = asyncio.get_event_loop()
    func = functools.partial(execCallBackApi, com, pram)
    await loop.run_in_executor(None, func)

def execCallBackApi(com, pram):
    ##### コールバックチェック #####
    ## 入力パラメータ生成
    execPayload = json.dumps({
        "processId" : pram
    })

    loopCnt = 0
    while True:
        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["コールバックチェック処理API_" + str(pram)]
            , "/ic/api/integration/v1/flows/rest/XXCCD011/1.0/RestCallBackCheck")
        loopCnt += 1

        if apiResponse["JobStatusCount"] > 0:
            ## 実行回数判定
            if loopCnt >= int(com.getEnvConstValue("MAX_LOOP_CNT")):
                com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                raise PyComnException("CCDE0005", ["コールバックチェック処理API_" + str(pram)])
            ## 待機
            time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))
            continue
        else:
            break

### Main処理 ###
def main():
    ## 共通処理インスタンス生成
    args = sys.argv
    com = Xxccdcomn("XXCCD016", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        fbdiName = com.paramChkAndConv("FBDI名", args[1], True, "str", 0)
        filePath = com.paramChkAndConv("ファイルパス", args[2], True, "str", 0)
        convDataApi = com.paramChkAndConv("データ変換処理API", args[3], True, "str", 0)

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

        ##### FBDI実行 #####
        fbdiFilePath = apiResponse["fbdiFilePath"]

        fileList = glob.glob(fbdiFilePath + "/*.zip")
        ## FBDIファイルが0件の場合
        if len(fileList) == 0:
            raise PyComnException("CCDI0004", [])

        ## FBDIファイル数分、FBDI実行APIを実行
        processIdList = []
        for files in fileList:
            ## 入力パラメータ生成
            execPayload = json.dumps({
                "FBDIName" : fbdiName,
                "filePath" : fbdiFilePath,
                "fileName" : os.path.basename(files)
            })
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["FBDI実行API_" + os.path.basename(files)]
                , "/ic/api/integration/v1/flows/rest/XXCCD007/1.0/RestFBDI")

            ## FBDI実行のプロセスIDにてリストを生成
            processIdList.append(apiResponse["processId"])

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["FBDI実行API"])

        ## FBDI実行API実行分、並列起動でコールバックチェックを実行
        loop = asyncio.get_event_loop()
        loop.run_until_complete(asyncio.gather(*[paraExecCallBackApi(com, x) for x in processIdList]))

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["コールバックチェック処理API"])

        ## FBDI実行API実行分の実行結果出力、ジョブステータスチェックを実行
        for processId in processIdList:
            ##### 共通 #####
            ## 入力パラメータ生成
            execPayload = json.dumps({
                "processId" : processId
            })

            ##### 実行結果出力 #####
            ## RESTAPI実行、エラー判定
            apiResponse = execApi(com, execPayload, ["実行結果出力API_" + str(processId)]
                , "/ic/api/integration/v1/flows/rest/XXCCD012/1.0/RestOutputFile")

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["実行結果出力API"])

            ##### ジョブ階層チェック #####
            loopCnt = 0
            while True:
                ## RESTAPI実行、エラー判定
                apiResponse = execApi(com, execPayload, ["ジョブ階層チェックAPI_" + str(processId)]
                    , "/ic/api/integration/v1/flows/rest/XXCCD031/1.0/RestJobTreeGet", False)
                loopCnt += 1

                ## 実行初回待機
                time.sleep(int(com.getEnvConstValue("SLEEP_TIME_JOBCK")))

                ## 正常ログ出力
                com.writeMsg("CCDI0002", ["ジョブ階層チェックAPI"])

                ##### 非同期処理チェック #####
                loopCntAsync = 0
                while True:
                    ## RESTAPI実行、エラー判定
                    apiResponse = execApi(com, execPayload, ["非同期処理チェックAPI"]
                        , "/ic/api/integration/v1/flows/rest/XXCCD036/1.0/RestAsyncCheck")
                    loopCntAsync += 1

                    if apiResponse["JobStatusCount"] == 1:
                        ## 実行回数判定
                        if loopCntAsync >= int(com.getEnvConstValue("MAX_LOOP_CNT_JOBCK")):
                            com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                            raise PyComnException("CCDE0005", ["非同期処理チェックAPI"])
                        ## 待機
                        time.sleep(int(com.getEnvConstValue("SLEEP_TIME_JOBCK")))
                        continue
                    else:
                        ## エラー詳細設定の場合はエラー処理
                        if apiResponse["errorDetail"]:
                            ####エラー処理
                            com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                            raise PyComnException("CCDE0002",["ジョブ階層チェックAPI_" + str(processId), apiResponse["returnCode"],apiResponse["message"], apiResponse["errorDetail"]])
                        break

                ## 正常ログ出力
                com.writeMsg("CCDI0002", ["非同期処理チェックAPI"])
                
                ##### ジョブステータス処理中チェック #####
                ## RESTAPI実行、エラー判定 ##
                apiResponse = execApi(com, execPayload, ["ジョブステータス処理中チェックAPI_" + str(processId)]
                , "/ic/api/integration/v1/flows/rest/XXCCD038/1.0/RestJobStatusProcessingCheck")

                if apiResponse["JobStatusCount"] > 0:
                    ## 実行回数判定
                    if loopCnt >= int(com.getEnvConstValue("MAX_LOOP_CNT")):
                        com.endCd = com.getEnvConstValue("JP1_ERR_CD")
                        raise PyComnException("CCDE0005", ["ジョブ階層チェックAPI_" + str(processId)])
                    ## 待機
                    time.sleep(int(com.getEnvConstValue("SLEEP_TIME")))
                    continue
                else:
                    break

            ## 正常ログ出力
            com.writeMsg("CCDI0002", ["ジョブステータス処理中チェックAPI"])

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
