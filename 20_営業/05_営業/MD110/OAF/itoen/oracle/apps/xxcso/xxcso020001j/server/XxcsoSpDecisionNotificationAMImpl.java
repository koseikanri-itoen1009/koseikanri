/*============================================================================
* ファイル名 : XxcsoSpDecisionNotificationAMImpl
* 概要説明   : SP専決通知画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * SP専決書の承認依頼／確認依頼／否決通知／返却通知／承認完了通知を行うための
 * アプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionNotificationAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionNotificationAMImpl()
  {
  }

  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   * @param notifyId 通知ID
   *****************************************************************************
   */
  public void initDetails(
    String notifyId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionNotificationVOImpl ntfVo
      = getXxcsoSpDecisionNotificationVO1();
    if ( ntfVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionNotificationVOImpl"
        );
    }

    ntfVo.initQuery(notifyId);
    
    XxcsoUtils.debug(txn, "[END]");
  }
  
  /**
   * 
   * Container's getter for XxcsoSpDecisionNotificationVO1
   */
  public XxcsoSpDecisionNotificationVOImpl getXxcsoSpDecisionNotificationVO1()
  {
    return (XxcsoSpDecisionNotificationVOImpl)findViewObject("XxcsoSpDecisionNotificationVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.server", "XxcsoSpDecisionNotificationAMLocal");
  }


}