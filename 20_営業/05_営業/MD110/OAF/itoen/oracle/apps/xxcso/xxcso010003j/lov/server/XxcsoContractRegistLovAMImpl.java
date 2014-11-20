/*============================================================================
* ファイル名 : XxcsoContractRegistAMImpl
* 概要説明   : 自販機設置契約情報登録画面LOVアプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.lov.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * 自販機設置契約情報登録画面LOVのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoContractVendorLovVO1
   */
  public XxcsoContractVendorLovVOImpl getXxcsoContractVendorLovVO1()
  {
    return (XxcsoContractVendorLovVOImpl)findViewObject("XxcsoContractVendorLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010003j.lov.server", "XxcsoContractRegistLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoContractInqueryBaseLovVO1
   */
  public XxcsoContractInqueryBaseLovVOImpl getXxcsoContractInqueryBaseLovVO1()
  {
    return (XxcsoContractInqueryBaseLovVOImpl)findViewObject("XxcsoContractInqueryBaseLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractBankLovVO1
   */
  public XxcsoContractBankLovVOImpl getXxcsoContractBankLovVO1()
  {
    return (XxcsoContractBankLovVOImpl)findViewObject("XxcsoContractBankLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractInstCodeLovVO1
   */
  public XxcsoContractInstCodeLovVOImpl getXxcsoContractInstCodeLovVO1()
  {
    return (XxcsoContractInstCodeLovVOImpl)findViewObject("XxcsoContractInstCodeLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractPubBaseLovVO1
   */
  public XxcsoContractPubBaseLovVOImpl getXxcsoContractPubBaseLovVO1()
  {
    return (XxcsoContractPubBaseLovVOImpl)findViewObject("XxcsoContractPubBaseLovVO1");
  }
}