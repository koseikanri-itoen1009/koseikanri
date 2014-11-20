/*============================================================================
* ファイル名 : XxcsoTransactionUtils
* 概要説明   : 【アドオン：営業・営業領域】共通トランザクションユーティリティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-06 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import java.sql.CallableStatement;
import java.sql.SQLException;

/*******************************************************************************
 * アドオン：共通トランザクションユーティリティクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTransactionUtils 
{
  /*****************************************************************************
   * モジュール設定
   * @param txn           OADBTransactionインスタンス
   * @param amClassName   クラス名（object.getClass().getName()）
   *****************************************************************************
   */
  public static void setModule(
    OADBTransaction txn
   ,String          amClassName
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_009002j_pkg.init_transaction(");
    sql.append("    iv_class_name => :1");
    sql.append("  );");
    sql.append("END;");

    CallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, amClassName);

      stmt = txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, amClassName);

      stmt.execute();
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw XxcsoMessage.createSqlErrorMessage(
        sqle
       ,XxcsoConstants.TOKEN_VALUE_SET_MODULE
      );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }
}