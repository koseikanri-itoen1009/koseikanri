/*============================================================================
* ファイル名 : XxcmnOAApplicationModuleImpl
* 概要説明   : 共通アプリケーションモジュール
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-17 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcmn.util.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
/***************************************************************************
 * 共通アプリケーションモジュールクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
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
}