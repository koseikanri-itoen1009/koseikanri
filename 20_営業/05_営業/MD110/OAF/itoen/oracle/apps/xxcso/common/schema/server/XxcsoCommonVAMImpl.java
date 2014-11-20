/*============================================================================
* ファイル名 : XxcsoCommonVAMImpl
* 概要説明   : アドオン営業共通検証アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * アドオン営業共通の検証アプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCommonVAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCommonVAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAsLeadVVO1
   */
  public XxcsoAsLeadVVOImpl getXxcsoAsLeadVVO1()
  {
    return (XxcsoAsLeadVVOImpl)findViewObject("XxcsoAsLeadVVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.common.schema.server", "XxcsoAsLeadVAMLocal");
  }


  /**
   * 
   * Container's getter for XxcsoGetOnlineSysdateVVO1
   */
  public XxcsoGetOnlineSysdateVVOImpl getXxcsoGetOnlineSysdateVVO1()
  {
    return (XxcsoGetOnlineSysdateVVOImpl)findViewObject("XxcsoGetOnlineSysdateVVO1");
  }

  /**
   * 
   * Container's getter for XxcsoGetAutoAssignedCodeVVO1
   */
  public XxcsoGetAutoAssignedCodeVVOImpl getXxcsoGetAutoAssignedCodeVVO1()
  {
    return (XxcsoGetAutoAssignedCodeVVOImpl)findViewObject("XxcsoGetAutoAssignedCodeVVO1");
  }

  /**
   * 
   * Container's getter for XxcsoCustAccountVVO1
   */
  public XxcsoCustAccountVVOImpl getXxcsoCustAccountVVO1()
  {
    return (XxcsoCustAccountVVOImpl)findViewObject("XxcsoCustAccountVVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderVVO1
   */
  public XxcsoSpDecisionHeaderVVOImpl getXxcsoSpDecisionHeaderVVO1()
  {
    return (XxcsoSpDecisionHeaderVVOImpl)findViewObject("XxcsoSpDecisionHeaderVVO1");
  }
}