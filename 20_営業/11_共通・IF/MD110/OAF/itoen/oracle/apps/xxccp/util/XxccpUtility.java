/*============================================================================
* ファイル名 : XxccpUtility
* 概要説明   : CCP共通関数
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.util;

import itoen.oracle.apps.xxccp.util.XxccpUtility2;
import itoen.oracle.apps.xxccp.util.XxccpConstants;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Date;

/***************************************************************************
 * 移動共通関数クラスです。
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpUtility 
{
  public XxccpUtility()
  {
  }

  /*****************************************************************************
  * SYSDATEを取得します。
  * @param trans - トランザクション
  * @return Date SYSDATE
  * @throws OAException - OA例外
  ****************************************************************************/
  public static Date getSysdate(
   OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getSysdate";
    Date   sysdate = null;

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                  );
    sb.append("   SELECT SYSDATE "      ); // SYSDATE
    sb.append("   INTO   :1 "           );
    sb.append("   FROM   DUAL; "        );
    sb.append("END; "                   );

    //PL/SQLの設定を行います
    CallableStatement cstmt
     = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
   try
   {
     // パラメータ設定(OUTパラメータ)
     cstmt.registerOutParameter(1, Types.DATE); // SYSDATE

     // PL/SQL実行
     cstmt.execute();
      
     // 戻り値取得
     sysdate = new Date(cstmt.getDate(1));

   // PL/SQL実行時例外の場合
   } catch(SQLException s)
   {
     // ロールバック
     rollBack(trans);
     XxccpUtility2.writeLog(
       trans,
       XxccpConstants.CLASS_XXCCP_UTILITY + XxccpConstants.DOT + apiName,
       s.toString(),
       6);
     // エラーメッセージ出力
     throw new OAException(
       XxccpConstants.APPL_XXCCP, 
       XxccpConstants.XXCCP191001);
   } finally
   {
     try
     {
       //処理中にエラーが発生した場合を想定する
       cstmt.close();
     } catch(SQLException s)
     {
       // ロールバック
       rollBack(trans);
       XxccpUtility2.writeLog(
         trans,
         XxccpConstants.CLASS_XXCCP_UTILITY + XxccpConstants.DOT + apiName,
         s.toString(),
         6);
       // エラーメッセージ出力
       throw new OAException(
         XxccpConstants.APPL_XXCCP, 
         XxccpConstants.XXCCP191003);
     }
   }
   return sysdate;
  } // getSysdate

  /***************************************************************************
   * ロールバック処理を行うメソッドです。
   * @param trans - トランザクション
   ***************************************************************************
   */
   public static void rollBack(
     OADBTransaction trans
   )
   {
     // ロールバック発行
     trans.executeCommand("ROLLBACK ");
   } // rollBack
   
  /***************************************************************************
   * コミット処理を行うメソッドです。
   * @param trans - トランザクション
   ***************************************************************************
   */
  public static void commit(
    OADBTransaction trans
  )
  {
    // コミット発行
    trans.executeCommand("COMMIT ");
  } // commit

}