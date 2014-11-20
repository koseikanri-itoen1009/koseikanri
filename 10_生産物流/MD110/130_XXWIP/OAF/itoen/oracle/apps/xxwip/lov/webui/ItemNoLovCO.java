/*============================================================================
* ファイル名 : ItemNoLovCO
* 概要説明   : 品目値リストコントローラ
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-28 1.0  二瓶大輔     新規作成
* 2010-01-18 1.1  伊藤ひとみ   本稼動障害#1151
*============================================================================
*/
package itoen.oracle.apps.xxwip.lov.webui;

import java.util.Dictionary;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
/***************************************************************************
 * 品目値リストコントローラクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.1
 ***************************************************************************
 */
public class ItemNoLovCO extends OAControllerImpl
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
    String invLocId = null;
    if (!XxcmnUtility.isBlankOrNull(passiveCriteriaItems.get("InventoryLocationId"))) 
    {
      invLocId = (String)passiveCriteriaItems.get("InventoryLocationId");
    }
    String destinationType = null;
    if (!XxcmnUtility.isBlankOrNull(passiveCriteriaItems.get("DestinationType"))) 
    {
      destinationType = (String)passiveCriteriaItems.get("DestinationType");
    }
    
    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("ItemNoVO1");
    vo.setWhereClause (null); // clean up from previous invokation
    vo.setWhereClauseParams (null); // clean up from previous invokation.
    vo.setWhereClauseParam(0, invLocId);
// 2010-01-18 H.Itou Add Start 本稼動障害#1151
    vo.setWhereClauseParam(1, invLocId);
    vo.setWhereClauseParam(2, invLocId);
    vo.setWhereClauseParam(3, invLocId);
    vo.setWhereClauseParam(4, invLocId);
    vo.setWhereClauseParam(5, invLocId);
    vo.setWhereClauseParam(6, invLocId);
// 2010-01-18 H.Itou Add End
    if ("1".equals(destinationType)) 
    {
      StringBuffer whereClause = new StringBuffer(1000);  // WHERE句作成用オブジェクト
      whereClause.append(" destination_type = '1' "); // 仕向区分
      vo.setWhereClause(whereClause.toString());
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
