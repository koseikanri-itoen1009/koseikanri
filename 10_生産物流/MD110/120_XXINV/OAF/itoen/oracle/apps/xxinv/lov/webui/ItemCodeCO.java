/*============================================================================
* ファイル名 : MovNumCO
* 概要説明   : 品目コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-04 1.0  大橋孝郎     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.lov.webui;

import java.util.Dictionary;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * 品目コントローラクラスです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.0
 ***************************************************************************
 */
public class ItemCodeCO extends OAControllerImpl
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
    String productFlg     = (String)passiveCriteriaItems.get("ProductFlg");
    String weightCapacity = (String)passiveCriteriaItems.get("WeightCapacity");

    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("ItemCodeVO1");
    vo.setWhereClause (null);
    vo.setWhereClauseParams (null);

    StringBuffer whereClause = new StringBuffer(1000);  // WHERE句作成用オブジェクト

    // 製品識別区分が１の場合
    if ("1".equals(productFlg))
    {
      whereClause.append(" item_class_code = :1");
      vo.setWhereClauseParam(0, XxinvConstants.ITEM_CLASS_5);
    // 製品識別区分が２の場合
    } else if ("2".equals(productFlg))
    {
      whereClause.append(" item_class_code != :1");
      vo.setWhereClauseParam(0, XxinvConstants.ITEM_CLASS_5);
    }

    // 重量容積区分が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(weightCapacity))
    {
      whereClause.append(" and weight_capacity = :2");
      vo.setWhereClauseParam(1, weightCapacity);
    }
    vo.setWhereClause(whereClause.toString());

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
