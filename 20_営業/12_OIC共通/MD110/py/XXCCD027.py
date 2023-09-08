"""
--------------------------------------------------------------------------------

     [概要]
        OIC実行ログのダウンロードREST APIを起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2023/02/15 Draft1A
          更新履歴：   SCSK   吉岡           2023/02/15 Draft1A  初版
                                             2023/02/28 Issue1.0 Issue化

     [戻り値]
        0 : 正常
        8 : 異常

     [パラメータ]
        取得日                               string

     [使用方法]
        /uspg/jp1/zb/py/T4/XXCCD027.py

--------------------------------------------------------------------------------
"""

import sys
import json
import requests
import os
import datetime

from com.Xxccdcomn import Xxccdcomn
from com.PyComnException import PyComnException

def execApi(com, execPayload, exeName, apiUrl):

    ## RESTAPI実行
    apiResponse = requests.request("GET"
        , com.getEnvValue("OIC_HOST") + apiUrl
        , headers=com.headers
        , params=execPayload)

    ## RESTAPIエラー判定
    com.oicErrChk(apiResponse, exeName)

    return apiResponse

### Main処理 ###
def main():
    ## 共通処理インスタンス生成
    args = sys.argv
    com = Xxccdcomn("XXCCD027", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        prmGetDate = com.paramChkAndConv("取得日", args[1], False, "str", 0)

        ##### OIC実行ログ定期ダウンロードAPI実行 #####
        ## 入力パラメータ生成
        nowDate = datetime.datetime.now()
        prmDate = (nowDate + datetime.timedelta(days=-1)).strftime("%Y-%m-%d")
        #入力パラメータ.取得日が設定されている場合は入力パラメータ.取得日を設定
        if prmGetDate:
            prmDate = prmGetDate

        execPayload = {
            "q" : "{startdate : '" + prmDate + " 00:00:00' , enddate : '" + prmDate + " 23:59:59'}"
        }

        ## RESTAPI実行、エラー判定
        apiResponse = execApi(com, execPayload, ["OIC実行ログ定期ダウンロードAPI"]
            , "/ic/api/integration/v1/monitoring/logs/icsflowlog/")

        ## 実行結果をzipファイル保存
        zipFileName = com.getEnvConstValue("ICSFLOWLOG_ZIP_FILENAME") + "_" + nowDate.strftime("%Y%m%d") + ".zip"
        with open(com.getEnvValue("ICSFLOWLOG_ZIP_FILEPATH") + zipFileName, "wb") as f:
            f.write(apiResponse.content)

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["OIC実行ログ定期ダウンロードAPI"])

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
