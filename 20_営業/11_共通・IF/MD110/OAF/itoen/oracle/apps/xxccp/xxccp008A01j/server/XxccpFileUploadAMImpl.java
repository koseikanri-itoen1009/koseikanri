/*============================================================================
* ファイル名 : XxccpFileUploadAMImpl.java
* 概要説明   : ファイルアップロードアプリケーションモジュール
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp008A01j.server;
import itoen.oracle.apps.xxccp.util.XxccpConstants;
import itoen.oracle.apps.xxccp.util.XxccpUtility2;
import itoen.oracle.apps.xxccp.util.server.XxccpOAApplicationModuleImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * ファイルアップロードアプリケーションモジュールクラスです。
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpFileUploadAMImpl extends XxccpOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpFileUploadAMImpl()
  {
  }

  /**
   * ファイルアップロードインターフェーステーブルレコード作成。
   */
  public void createXxccpMrpFileUlInterfaceRec()
  {
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxccpMrpFileUlInterfaceVO1();
    if (!vo.isPreparedForExecution())
    {
      vo.executeQuery();
    }
    // 新規行を作成する。
    OARow row = (OARow)vo.createRow();
    vo.insertRow(row);
  }

  /**
   * データベースと中間層をロールバックする。
   */
  public void rollbackXxccpMrpFileUlInterface()
  {
    OADBTransaction txn = getOADBTransaction();
    if (txn.isDirty())
    {
      txn.rollback();
    }
  }

  /**
   * トランザクションのコミット。
   */
  public void apply()
  {
    getTransaction().commit();
  }

  /**
    * アップロードファイル情報設定。
    * @param fileName アップロードファイル名
    * @param conType  アップロードファイルコンテントタイプ
    */
  public void setUlFileInfo(
    String fileName, 
    String conType)
  {
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxccpMrpFileUlInterfaceVO1();
    OARow row = (OARow)vo.getCurrentRow();
    row.setAttribute("FileName", fileName);
    row.setAttribute("FileContentType", conType);
      
  }

  /**
   * 参照タイプより、コンカレント名称およびフォーマットパターンを取得する。
   * @param lookuptype - タイプ
   * @param conType - コード(コンテントタイプコード)
   * @return String - Meaning
   */
  public String getLookUpValue(String lookuptype, String conType)
  {
    XxccpLookUpValueVOImpl vo = getXxccpLookUpValueVO1();
    vo.getLookUpValue(lookuptype, conType);
    OARow row = (OARow)vo.first();
    return (String)row.getAttribute("Meaning");
  }

  /**
   * アップロードコンカレントの起動。
   * @param concName - コンカレント名称
   * @param formatPattern - フォーマットパターン
   * @return long - 要求id
   */
  public long concRun(
    String concName, 
    String formatPattern)
  {
    // ストアドプロシージャを実行させるためのインターフェース
    CallableStatement stmt = null;
    try
    {
      // ファイルIDの取得
      OAViewObjectImpl vo = (OAViewObjectImpl)getXxccpMrpFileUlInterfaceVO1();
      OARow row = (OARow)vo.getCurrentRow();
      Number fileId = (Number)row.getAttribute("FileId");
      // トランザクションの取得
      OADBTransaction trans = getOADBTransaction();
      // プロシージャ
      StringBuffer sb = new StringBuffer(100);
      sb.append("DECLARE ");
      sb.append("  lt_application_short_name  fnd_application.application_short_name%TYPE; ");
      sb.append("BEGIN ");
      sb.append("  SELECT fa.application_short_name              ");
      sb.append("  INTO   lt_application_short_name              ");
      sb.append("  FROM   fnd_concurrent_programs fcp            "); // コンカレントプログラム
      sb.append("        ,fnd_application         fa             "); // アプリケーション
      sb.append("  WHERE  fcp.application_id = fa.application_id ");
      sb.append("  AND    fcp.concurrent_program_name = :1       "); // コンカレント名
      sb.append("  AND    fcp.enabled_flag = 'Y';                "); // 有効フラグ
      sb.append("  fnd_global.apps_initialize(:2, :3, :4); ");
      sb.append("  :5 := fnd_request.submit_request( ");
      sb.append("           lt_application_short_name  "); // アプリケーション短縮名
      sb.append("         , :6      ");
      sb.append("         , NULL    ");
      sb.append("         , NULL ");
      sb.append("         , FALSE   ");
      sb.append("         , :7      ");
      sb.append("         , :8 );   ");
      sb.append("END; ");
      stmt = trans.createCallableStatement(sb.toString(), 0);
      // バインド変数に値をセットする
      stmt.setString(1, "" + concName);
      stmt.setInt(2, trans.getUserId());
      stmt.setInt(3, trans.getResponsibilityId());
      stmt.setInt(4, trans.getResponsibilityApplicationId());
      stmt.registerOutParameter(5, Types.BIGINT);
      stmt.setString(6, "" + concName);
      stmt.setLong(7, fileId.longValue());
      stmt.setString(8, "" + formatPattern);
      // プロシージャの実行
      stmt.execute();
      return stmt.getLong(5);
    } catch(SQLException e)
    {
      // ログ出力
      XxccpUtility2.writeLog(getOADBTransaction(),
                          getClass().getName() + 
                          XxccpConstants.DOT + "concRun",
                          e.toString(),
                          6);
      throw OAException.wrapperException(e);
    } finally
    {
      if (stmt != null)
      {
        try
        {
          stmt.close();
        } catch (SQLException e2)
        {
          // ログ出力
          XxccpUtility2.writeLog(getOADBTransaction(),
                                getClass().getName() + 
                                XxccpConstants.DOT + "concRun",
                                e2.toString(),
                                6);
          throw OAException.wrapperException(e2);
        }
      }
    }
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxccp.xxccp008A01j.server", "XxccpFileUploadAMLocal");
  }


  /**
   * 
   * Container's getter for XxccpLookUpValueVO1
   */
  public XxccpLookUpValueVOImpl getXxccpLookUpValueVO1()
  {
    return (XxccpLookUpValueVOImpl)findViewObject("XxccpLookUpValueVO1");
  }

  /**
   * 
   * Container's getter for XxccpMrpFileUlInterfaceVO1
   */
  public OAViewObjectImpl getXxccpMrpFileUlInterfaceVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxccpMrpFileUlInterfaceVO1");
  }

}