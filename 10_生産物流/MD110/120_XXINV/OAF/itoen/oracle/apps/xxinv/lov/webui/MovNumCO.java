/*============================================================================
* ファイル名 : MovNumCO
* 概要説明   : 移動番号コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  大橋孝郎     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.lov.webui;

import java.util.Dictionary;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * 移動番号コントローラクラスです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.0
 ***************************************************************************
 */
public class MovNumCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    Dictionary passiveCriteriaItems = pageContext.getLovCriteriaItems();
    String peopleCode     = (String)passiveCriteriaItems.get("PeopleCode");
    String actualFlg      = (String)passiveCriteriaItems.get("ActualFlg");
    String productFlg     = (String)passiveCriteriaItems.get("ProductFlg");
    String shippedLocatId = (String)passiveCriteriaItems.get("ShippedId");
    String shipToLocatId  = (String)passiveCriteriaItems.get("ShipToId");
    
    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("MovNumVO1");
    vo.setWhereClause (null);
    vo.setWhereClauseParams (null);
    vo.setWhereClauseParam(0, productFlg);

    // 外部ユーザの場合
    if (XxinvConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      // 入力パラメータ実績データ区分が1(出庫実績)かつ出庫元IDが入力されていた場合
      if ((!XxcmnUtility.isBlankOrNull(shippedLocatId)) && ("1".equals(actualFlg)))
      {
        vo.setWhereClause(" shipped_locat_id = :2");
        vo.setWhereClauseParam(1, shippedLocatId);


      // 入力パラメータ実績データ区分が2(入庫実績)かつ入庫先IDが入力されていた場合
      } else if ((!XxcmnUtility.isBlankOrNull(shipToLocatId)) && ("2".equals(actualFlg)))
      {
        vo.setWhereClause (" ship_to_locat_id = :2");
        vo.setWhereClauseParam(1, shipToLocatId);

      }
      
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
  }

}
