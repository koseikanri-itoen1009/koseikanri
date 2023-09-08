"""
--------------------------------------------------------------------------------

     [概要]
        プロファイル値更新のREST APIを起動します。

     [作成/更新履歴]
          作成者  ：   SCSK   吉岡           2022/06/30 Draft1A
          更新履歴：   SCSK   吉岡           2022/06/30 Draft1A  初版
                       SCSK   久保田         2023/02/22 Issue1.0 Issue化

     [戻り値]
        0 : 正常
        8 : 異常

     [パラメータ]
        プロファイルオプションID             int
        レベル名                             string
        レベル値                             string
        プロファイルオプション値             string

     [使用方法]
        /u02/pv/XXCCD014.py

--------------------------------------------------------------------------------
"""

import sys
import json
import requests
import os

from com.Xxccdcomn import Xxccdcomn
from com.PyComnException import PyComnException

### Main処理 ###
def main():
    ## 共通処理インスタンス生成
    args = sys.argv
    com = Xxccdcomn("XXCCD014", os.path.dirname(args[0]))

    try:
        ## パラメータチェック、コマンドライン引数型変換
        profileOptionId = com.paramChkAndConv("プロファイルオプションID", args[1], True, "int", 0)
        levelName = com.paramChkAndConv("レベル名", args[2], True, "str", 0)
        levelValue = com.paramChkAndConv("レベル値", args[3], True, "str", 0)
        profileOptionValue = com.paramChkAndConv("プロファイルオプション値", args[4], True, "str", 0)

        ##### プロファイル値更新 #####
        ## 入力パラメータ生成
        execPayload = json.dumps({
            "profileOptionId" : profileOptionId,
            "levelName" : levelName,
            "levelValue" : levelValue,
            "profileOptionValue" : profileOptionValue
        })
        ## RESTAPI実行
        apiResponse = requests.request("POST"
            , com.getEnvValue("OIC_HOST") + "/ic/api/integration/v1/flows/rest/XXCCD001/1.0/RestProfileOptionValueUpdate"
            , headers=com.headers
            , data=execPayload)

        ## RESTAPIエラー判定
        com.oicErrChk(apiResponse, ["プロファイル値更新"])

        ## 正常ログ出力
        com.writeMsg("CCDI0002", ["プロファイル値更新"])

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
