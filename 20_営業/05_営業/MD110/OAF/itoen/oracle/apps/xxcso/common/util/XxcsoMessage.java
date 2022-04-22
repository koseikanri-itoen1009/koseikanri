/*============================================================================
* ファイル名 : XxcsoMessage
* 概要説明   : メッセージ作成クラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS小川浩    新規作成
* 2008-11-11 1.0  SCS小川浩    createMessageを修正
* 2008-11-20 1.0  SCS小川浩    コメントに@returnを記述
* 2008-11-20 1.0  SCS小川浩    警告終了メッセージ作成処理を追加
* 2008-11-27 1.0  SCS柳平直人  SQLエラーメッセージ作成処理を追加
* 2008-12-02 1.0  SCS柳平直人  CSV作成時エラーメッセージ作成処理を追加
* 2008-12-05 1.0  SCS小川浩    準正常系エラーメッセージ作成処理を追加
* 2008-12-05 1.0  SCS小川浩    異常系エラーメッセージ作成処理を追加
* 2008-12-07 1.0  SCS小川浩    更新データなし警告メッセージ作成処理を追加
* 2008-12-10 1.0  SCS小川浩    最大登録件数エラーメッセージ作成処理を追加
* 2008-12-11 1.0  SCS小川浩    正常終了メッセージ作成処理を追加
* 2022-04-05 1.1  SCSK二村悠香 [E_本稼動_18060]自販機顧客別利益管理
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import java.sql.SQLException;
import java.io.UnsupportedEncodingException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;

/*******************************************************************************
 * アドオン：メッセージを作成するクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoMessage 
{
  /*****************************************************************************
   * 正常終了時のメッセージを作成します（トークン無）。
   * @param messageName メッセージ名
   * @return OAException 正常メッセージ
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName
  )
  {
    return
      createConfirmMessage(
        messageName,
        null,
        null
      );
  }

  /*****************************************************************************
   * 正常終了時のメッセージを作成します（トークン１）。
   * @param messageName メッセージ名
   * @param tokenName   トークン名
   * @param tokenValue  トークン値
   * @return OAException 正常メッセージ
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName,
    String tokenName,
    String tokenValue
  )
  {
    return
      createConfirmMessage(
        messageName,
        tokenName,
        tokenValue,
        null,
        null
      );
  }

  /*****************************************************************************
   * 正常終了時のメッセージを作成します（トークン２）。
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @return OAException 正常メッセージ
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2
  )
  {
    return
      createConfirmMessage(
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        null,
        null
      );    
  }

  /*****************************************************************************
   * 正常終了時のメッセージを作成します（トークン３）。
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @param tokenName3  トークン３名
   * @param tokenValue3 トークン３値
   * @return OAException 正常メッセージ
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.CONFIRMATION,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3
      );
  }

  /*****************************************************************************
   * 警告終了時のメッセージを作成します（トークン無）。
   * @param messageName メッセージ名
   * @return OAException 警告メッセージ
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName
  )
  {
    return
      createWarningMessage(
        messageName,
        null,
        null
      );        
  }

  /*****************************************************************************
   * 警告終了時のメッセージを作成します（トークン１）。
   * @param messageName メッセージ名
   * @param tokenName   トークン名
   * @param tokenValue  トークン値
   * @return OAException 警告メッセージ
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName,
    String tokenValue
  )
  {
    return
      createWarningMessage(
        messageName,
        tokenName,
        tokenValue,
        null,
        null
      );        
  }

  /*****************************************************************************
   * 警告終了時のメッセージを作成します（トークン２）。
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @return OAException 警告メッセージ
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2
  )
  {
    return
      createWarningMessage(
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        null,
        null
      );    
  }

  /*****************************************************************************
   * 警告終了時のメッセージを作成します（トークン３）。
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @param tokenName3  トークン３名
   * @param tokenValue3 トークン３値
   * @return OAException 警告メッセージ
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.WARNING,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3
      );
  }

// Ver.1.1 Add Start
  /*****************************************************************************
   * 警告終了時のメッセージを作成します（トークン３）。
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @param tokenName3  トークン３名
   * @param tokenValue3 トークン３値
   * @param tokenName4  トークン４名
   * @param tokenValue4 トークン４値
   * @param tokenName5  トークン５名
   * @param tokenValue5 トークン５値
   * @param tokenName6  トークン６名
   * @param tokenValue6 トークン６値
   * @return OAException 警告メッセージ
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3,
    String tokenName4,
    String tokenValue4,
    String tokenName5,
    String tokenValue5,
    String tokenName6,
    String tokenValue6
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.WARNING,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3,
        tokenName4,
        tokenValue4,
        tokenName5,
        tokenValue5,
        tokenName6,
        tokenValue6
      );
  }
// Ver.1.1 Add End

  /*****************************************************************************
   * エラー終了時のメッセージを作成します（トークン無）。
   * @param messageName メッセージ名
   * @return OAException エラーメッセージ
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName
  )
  {
    return
      createErrorMessage(
        messageName,
        null,
        null
      );        
  }

  /*****************************************************************************
   * エラー終了時のメッセージを作成します（トークン１）。
   * @param messageName メッセージ名
   * @param tokenName   トークン名
   * @param tokenValue  トークン値
   * @return OAException エラーメッセージ
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName,
    String tokenName,
    String tokenValue
  )
  {
    return
      createErrorMessage(
        messageName,
        tokenName,
        tokenValue,
        null,
        null
      );        
  }

  /*****************************************************************************
   * エラー終了時のメッセージを作成します（トークン２）。
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @return OAException エラーメッセージ
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2
  )
  {
    return
      createErrorMessage(
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        null,
        null
      );    
  }

  /*****************************************************************************
   * エラー終了時のメッセージを作成します（トークン３）。
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @param tokenName3  トークン３名
   * @param tokenValue3 トークン３値
   * @return OAException エラーメッセージ
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.ERROR,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3
      );
  }

  /*****************************************************************************
   * インスタンス取得エラーメッセージ取得
   * @param instanceName インスタンス名
   * @return OAException インスタンス取得エラーメッセージ
   *****************************************************************************
   */
  public static OAException createInstanceLostError(
    String instanceName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00120,
        XxcsoConstants.TOKEN_INSTANCE_NAME,
        instanceName
      );
  }

  /*****************************************************************************
   * トランザクションロックエラーメッセージ取得
   * @param recordName レコード名
   * @return OAException トランザクションロックエラーメッセージ
   *****************************************************************************
   */
  public static OAException createTransactionLockError(
    String recordName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00002,
        XxcsoConstants.TOKEN_RECORD,
        recordName
      );
  }

  /*****************************************************************************
   * トランザクション矛盾エラーメッセージ取得
   * @param recordName レコード名
   * @return OAException トランザクション矛盾エラーメッセージ
   *****************************************************************************
   */
  public static OAException createTransactionInconsistentError(
    String recordName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00003,
        XxcsoConstants.TOKEN_RECORD,
        recordName
      );
  }

  /*****************************************************************************
   * 行なしエラーメッセージ取得
   * @param recordName レコード名
   * @return OAException 行なしエラーメッセージ
   *****************************************************************************
   */
  public static OAException createRecordNotFoundError(
    String recordName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00004,
        XxcsoConstants.TOKEN_RECORD,
        recordName
      );
  }

  /*****************************************************************************
   * プロファイル・オプション値取得失敗エラーメッセージ取得
   * @param profileOptionName プロファイル・オプション名
   * @return OAException プロファイル・オプション値取得失敗エラーメッセージ
   *****************************************************************************
   */
  public static OAException createProfileNotFoundError(
    String profileOptionName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00014,
        XxcsoConstants.TOKEN_PROF_NAME,
        profileOptionName
      );
  }

  /*****************************************************************************
   * プロファイル・オプション値型変換失敗エラーメッセージ取得
   * @param profileOptionName  プロファイル・オプション名
   * @param profileOptionValue プロファイル・オプション値
   * @return OAException プロファイル・オプション値型変換失敗エラーメッセージ
   *****************************************************************************
   */
  public static OAException createProfileOptionValueError(
    String profileOptionName,
    String profileOptionValue
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00121,
        XxcsoConstants.TOKEN_PROF_NAME,
        profileOptionName,
        XxcsoConstants.TOKEN_PROF_VALUE,
        profileOptionValue
      );
  }

  /*****************************************************************************
   * SQLエラーメッセージ作成
   * @param ex  SQLException
   * @param actionValue プロファイル・オプション値
   * @return OAException SQLエラーメッセージ
   *****************************************************************************
   */
  public static OAException createSqlErrorMessage(
    SQLException ex,
    String actionValue
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00236,
        XxcsoConstants.TOKEN_ACTION,
        actionValue,
        XxcsoConstants.TOKEN_ERRMSG,
        ex.getMessage()
      );
  }

  /*****************************************************************************
   * CSV作成時エラーメッセージ作成
   * @param ex  UnsupportedEncodingException
   * @return OAException CSV作成時エラーメッセージ
   *****************************************************************************
   */
  public static OAException createCsvErrorMessage(
    UnsupportedEncodingException uae
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00236,
        XxcsoConstants.TOKEN_ACTION,
        XxcsoConstants.TOKEN_VALUE_CSV_CREATE,
        XxcsoConstants.TOKEN_ERRMSG,
        uae.getMessage()
      );
  }

  /*****************************************************************************
   * 準正常系エラーメッセージ作成
   * @param actionName   アクション名
   * @param errorMessage 準正常系エラーメッセージ
   * @return OAException 準正常系エラーメッセージ
   *****************************************************************************
   */
  public static OAException createAssociateErrorMessage(
    String actionName,
    String errorMessage
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00042,
        XxcsoConstants.TOKEN_ACTION,
        actionName,
        XxcsoConstants.TOKEN_ERRMSG,
        errorMessage
      );
  }

  /*****************************************************************************
   * 異常系エラーメッセージ作成
   * @param actionName   アクション名
   * @param errorMessage 異常系エラーメッセージ
   * @return OAException 異常系エラーメッセージ
   *****************************************************************************
   */
  public static OAException createCriticalErrorMessage(
    String actionName,
    String errorMessage
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00236,
        XxcsoConstants.TOKEN_ACTION,
        actionName,
        XxcsoConstants.TOKEN_ERRMSG,
        errorMessage
      );
  }

  /*****************************************************************************
   * 更新データなし警告メッセージ作成
   * @return OAException 更新データなし警告エラーメッセージ
   *****************************************************************************
   */
  public static OAException createNotChangedMessage(
  )
  {
    return createWarningMessage(XxcsoConstants.APP_XXCSO1_00336);
  }

  /*****************************************************************************
   * 最大登録件数エラーメッセージ作成
   * @param objectName   オブジェクト名
   * @param maxSize      最大登録件数
   * @return OAException 異常系エラーメッセージ
   *****************************************************************************
   */
  public static OAException createMaxRowException(
    String objectName,
    String maxSize
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00010,
        XxcsoConstants.TOKEN_OBJECT,
        objectName,
        XxcsoConstants.TOKEN_MAX_SIZE,
        maxSize
      );
  }

  /*****************************************************************************
   * 削除確認メッセージ作成
   * @param columnName   カラム名
   * @param values       値
   * @return OAException 確認メッセージ
   *****************************************************************************
   */
  public static OAException createDeleteWarningMessage(
    String columnName,
    String values
  )
  {
    return
      createWarningMessage(
        XxcsoConstants.APP_XXCSO1_00460,
        XxcsoConstants.TOKEN_COLUMN,
        columnName,
        XxcsoConstants.TOKEN_VALUES,
        values
      );
  }

  /*****************************************************************************
   * 正常終了メッセージ作成
   * @param record       対象レコード
   * @param action       実行名
   * @return OAException 正常終了メッセージ
   *****************************************************************************
   */
  public static OAException createCompleteMessage(
    String record,
    String action
  )
  {
    return
      createConfirmMessage(
        XxcsoConstants.APP_XXCSO1_00001,
        XxcsoConstants.TOKEN_RECORD,
        record,
        XxcsoConstants.TOKEN_ACTION,
        action
      );
  }

  /*****************************************************************************
   * メッセージを作成します。
   * @param applicationShortName アプリケーション短縮名
   * @param messageType メッセージタイプ
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @param tokenName3  トークン３名
   * @param tokenValue3 トークン３値
   * @return OAException エラーメッセージ
   *****************************************************************************
   */
  public static OAException createMessage(
    String applicationShortName,
    byte messageType,
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    OAException msg = null;
    
    if ( tokenName1 == null && tokenName2 == null && tokenName3 == null)
    {
      msg = new OAException(
        applicationShortName,
        messageName,
        null,
        messageType,
        null
      );
    }
    if ( tokenName1 != null && tokenName2 == null && tokenName3 == null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    if ( tokenName1 != null && tokenName2 != null && tokenName3 == null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1),
        new MessageToken(tokenName2, tokenValue2)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    if ( tokenName1 != null && tokenName2 != null && tokenName3 != null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1),
        new MessageToken(tokenName2, tokenValue2),
        new MessageToken(tokenName3, tokenValue3)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    return msg;
  }

// Ver.1.1 Add Start
  /*****************************************************************************
   * メッセージを作成します。
   * @param applicationShortName アプリケーション短縮名
   * @param messageType メッセージタイプ
   * @param messageName メッセージ名
   * @param tokenName1  トークン１名
   * @param tokenValue1 トークン１値
   * @param tokenName2  トークン２名
   * @param tokenValue2 トークン２値
   * @param tokenName3  トークン３名
   * @param tokenValue3 トークン３値
   * @param tokenName4  トークン４名
   * @param tokenValue4 トークン４値
   * @param tokenName5  トークン５名
   * @param tokenValue5 トークン５値
   * @param tokenName6  トークン６名
   * @param tokenValue6 トークン６値
   * @return OAException エラーメッセージ
   *****************************************************************************
   */
  public static OAException createMessage(
    String applicationShortName,
    byte messageType,
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3,
    String tokenName4,
    String tokenValue4,
    String tokenName5,
    String tokenValue5,
    String tokenName6,
    String tokenValue6
  )
  {
    OAException msg = null;
    
    if ( tokenName1 != null && tokenName2 != null && tokenName3 != null && tokenName4 != null && tokenName5 != null && tokenName6 != null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1),
        new MessageToken(tokenName2, tokenValue2),
        new MessageToken(tokenName3, tokenValue3),
        new MessageToken(tokenName4, tokenValue4),
        new MessageToken(tokenName5, tokenValue5),
        new MessageToken(tokenName6, tokenValue6)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    return msg;
  }
// Ver.1.1 Add End
}