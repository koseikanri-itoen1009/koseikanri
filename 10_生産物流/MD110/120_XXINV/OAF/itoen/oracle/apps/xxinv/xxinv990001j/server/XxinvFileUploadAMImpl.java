/*============================================================================
* ファイル名 : XxinvFileUploadAMImpl.java
* 概要説明   : ファイルアップロードアプリケーションモジュール
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-23 1.0  高梨雅史      新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv990001j.server;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;

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
 * @author  ORACLE 高梨雅史
 * @version 1.0
 ***************************************************************************
 */
public class XxinvFileUploadAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvFileUploadAMImpl()
  {
  }

  /**
   * ファイルアップロードインターフェーステーブルレコード作成。
   */
  public void createXxinvMrpFileUlInterfaceRec()
  {
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxinvMrpFileUlInterfaceVO1();
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
  public void rollbackXxinvMrpFileUlInterface()
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
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxinvMrpFileUlInterfaceVO1();
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
    XxinvLookUpValueVOImpl vo = getXxinvLookUpValueVO1();
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
      OAViewObjectImpl vo = (OAViewObjectImpl)getXxinvMrpFileUlInterfaceVO1();
      OARow row = (OARow)vo.getCurrentRow();
      Number fileId = (Number)row.getAttribute("FileId");
      // トランザクションの取得
      OADBTransaction trans = getOADBTransaction();
      // プロシージャ
      StringBuffer sb = new StringBuffer(100);
      sb.append("BEGIN ");
      sb.append("  fnd_global.apps_initialize(:1, :2, :3); ");
      sb.append("  :4 := fnd_request.submit_request( ");
      sb.append("          'XXINV'  ");
      sb.append("         , :5      ");
      sb.append("         , NULL    ");
      sb.append("         , SYSDATE ");
      sb.append("         , FALSE   ");
      sb.append("         , :6      ");
      sb.append("         , :7 );   ");
      sb.append("END; ");
      stmt = trans.createCallableStatement(sb.toString(), 0);
      // バインド変数に値をセットする
      stmt.setInt(1, trans.getUserId());
      stmt.setInt(2, trans.getResponsibilityId());
      stmt.setInt(3, trans.getResponsibilityApplicationId());
      stmt.registerOutParameter(4, Types.BIGINT);
      stmt.setString(5, "" + concName);
      stmt.setLong(6, fileId.longValue());
      stmt.setString(7, "" + formatPattern);

      // プロシージャの実行
      stmt.execute();
      return stmt.getLong(4);
    } catch(SQLException e)
    {
      // ログ出力
      XxcmnUtility.writeLog(getOADBTransaction(),
                          getClass().getName() + 
                          XxcmnConstants.DOT + "concRun",
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
          XxcmnUtility.writeLog(getOADBTransaction(),
                                getClass().getName() + 
                                XxcmnConstants.DOT + "concRun",
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
    launchTester("itoen.oracle.apps.xxinv.xxinv990001j.server", "XxinvFileUploadAMLocal");
  }


  /**
   * 
   * Container's getter for XxinvLookUpValueVO1
   */
  public XxinvLookUpValueVOImpl getXxinvLookUpValueVO1()
  {
    return (XxinvLookUpValueVOImpl)findViewObject("XxinvLookUpValueVO1");
  }

  /**
   * 
   * Container's getter for XxinvMrpFileUlInterfaceVO1
   */
  public OAViewObjectImpl getXxinvMrpFileUlInterfaceVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxinvMrpFileUlInterfaceVO1");
  }

}