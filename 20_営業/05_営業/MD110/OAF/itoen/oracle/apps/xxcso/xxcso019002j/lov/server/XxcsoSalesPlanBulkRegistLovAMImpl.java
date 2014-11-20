/*============================================================================
* ファイル名 : XxcsoSalesPlanBulkRegistLovAM
* 概要説明   : 担当営業員LOV用アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-04-22 1.0  SCS柳平直人  新規作成([ST障害T1_0585]による追加)
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.lov.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * 担当営業員LOVのアプリケーション・モジュールクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanBulkRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanBulkRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for SalesPlanResorcesLovVO
   */
  public XxcsoSalesPlanResorcesLovVOImpl getSalesPlanResorcesLovVO()
  {
    return (XxcsoSalesPlanResorcesLovVOImpl)findViewObject("SalesPlanResorcesLovVO");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019002j.lov.server", "XxcsoSalesPlanBulkRegistLovAMLocal");
  }
}