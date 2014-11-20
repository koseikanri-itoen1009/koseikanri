/*============================================================================
* ファイル名 : XxccpOAApplicationModuleImpl
* 概要説明   : 共通アプリケーションモジュール
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.util.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
/***************************************************************************
 * 共通アプリケーションモジュールクラスです。
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpOAApplicationModuleImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpOAApplicationModuleImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxccp.util.server", "XxccpOAApplicationModuleImplLocal");
  }

  /***************************************************************************
   * 変更に関する警告をクリアします。
   ***************************************************************************
   */
  public void clearWarnAboutChanges()
  {
    // ステータスを変更なしに戻す
    getOADBTransaction().setPlsqlState(OADBTransaction.STATUS_UNMODIFIED);
  } // clearWarnAboutChanges

  /***************************************************************************
   * 変更に関する警告を設定します。
   ***************************************************************************
   */
  public void setWarnAboutChanges()
  {
    // ステータスを変更有りにする
    getOADBTransaction().setPlsqlState(OADBTransaction.STATUS_DIRTY);
  } // setWarnAboutChanges
}