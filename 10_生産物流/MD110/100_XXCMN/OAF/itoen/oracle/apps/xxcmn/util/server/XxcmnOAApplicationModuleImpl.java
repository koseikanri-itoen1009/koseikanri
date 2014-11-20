/*============================================================================
* ファイル名 : XxcmnOAApplicationModuleImpl
* 概要説明   : 共通アプリケーションモジュール
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-17 1.0  二瓶大輔     新規作成
* 2008-08-13 1.1  二瓶大輔     clearWarnAboutChanges
*                              setWarnAboutChangesメソッド追加
*============================================================================
*/
package itoen.oracle.apps.xxcmn.util.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
/***************************************************************************
 * 共通アプリケーションモジュールクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.1
 ***************************************************************************
 */
public class XxcmnOAApplicationModuleImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcmnOAApplicationModuleImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcmn.util.server", "XxcmnOAApplicationModuleImplLocal");
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