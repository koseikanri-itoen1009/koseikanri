/*============================================================================
* ファイル名 : ShipToLocatCO
* 概要説明   : 入庫先コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-05-16 1.0  大橋孝郎     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.lov.webui;

import java.util.Dictionary;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAApplicationModule;

import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * 入庫先コントローラクラスです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.0
 ***************************************************************************
 */
public class ShipToLocatCO extends OAControllerImpl
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
    String peopleCode = (String)passiveCriteriaItems.get("PeopleCode");

    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("LocationsCodeVO1");
    vo.setWhereClause (null);
    vo.setWhereClauseParams (null);

    // 外部ユーザの場合
    if (XxinvConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      vo.setWhereClause(" user_id = FND_GLOBAL.USER_ID");

    // 内部ユーザの場合
    } else
    {
      vo.setWhereClause(" user_id = -1");
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
