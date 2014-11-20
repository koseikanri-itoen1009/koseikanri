/*============================================================================
* ファイル名 : XxcsoSpDecisionRegistLovAMImpl
* 概要説明   : SP専決登録画面LOV用アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * SP専決登録画面のLOVのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAccountForRegistLovVO1
   */
  public XxcsoAccountForRegistLovVOImpl getXxcsoAccountForRegistLovVO1()
  {
    return (XxcsoAccountForRegistLovVOImpl)findViewObject("XxcsoAccountForRegistLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.lov.server", "XxcsoAccountForRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoPublishBaseLovVO1
   */
  public XxcsoPublishBaseLovVOImpl getXxcsoPublishBaseLovVO1()
  {
    return (XxcsoPublishBaseLovVOImpl)findViewObject("XxcsoPublishBaseLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoVendorModelLovVO1
   */
  public XxcsoVendorModelLovVOImpl getXxcsoVendorModelLovVO1()
  {
    return (XxcsoVendorModelLovVOImpl)findViewObject("XxcsoVendorModelLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractLovVO1
   */
  public XxcsoContractLovVOImpl getXxcsoContractLovVO1()
  {
    return (XxcsoContractLovVOImpl)findViewObject("XxcsoContractLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoVendorLovVO1
   */
  public XxcsoVendorLovVOImpl getXxcsoVendorLovVO1()
  {
    return (XxcsoVendorLovVOImpl)findViewObject("XxcsoVendorLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoApproveCodeLovVO1
   */
  public XxcsoApproveCodeLovVOImpl getXxcsoApproveCodeLovVO1()
  {
    return (XxcsoApproveCodeLovVOImpl)findViewObject("XxcsoApproveCodeLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoOtherContentLoVO1
   */
  public XxcsoOtherContentLoVOImpl getXxcsoOtherContentLoVO1()
  {
    return (XxcsoOtherContentLoVOImpl)findViewObject("XxcsoOtherContentLoVO1");
  }
}