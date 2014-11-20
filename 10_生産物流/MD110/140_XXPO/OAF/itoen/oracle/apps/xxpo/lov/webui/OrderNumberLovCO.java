/*============================================================================
* ファイル名 : OrderNumberLovCO
* 概要説明   : 発注Noリストコントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-13 1.0  吉元強樹     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.lov.webui;

import java.util.Dictionary;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

/***************************************************************************
 * 発注Noリストコントローラです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class OrderNumberLovCO extends OAControllerImpl
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

    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    Dictionary passiveCriteriaItems = pageContext.getLovCriteriaItems();

    // 従業員区分
    String peopleCode = null;
// 20080528 yoshimoto add Start
    // 仕入先サイトコード
    String purchaseSiteCode = null;
// 20080528 yoshimoto add End

    if (!XxcmnUtility.isBlankOrNull(passiveCriteriaItems.get("PeopleCode"))) 
    {
      peopleCode = (String)passiveCriteriaItems.get("PeopleCode");
// 20080528 yoshimoto add Start
      purchaseSiteCode = (String)passiveCriteriaItems.get("PurchaseSiteCode");
// 20080528 yoshimoto add End
    }

    // 従業員区分が2:外部の場合、『納入先 = 自倉庫』を追加
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {

      StringBuffer whereClause = new StringBuffer(1000);  // WHERE句作成用オブジェクト

      // 発注NoVOを取得
      OAViewObject orderNumberVO = (OAViewObject)am.findViewObject("OrderNumberVO1");

      // 初期化
      orderNumberVO.setWhereClause(null);       // clean up from previous invokation
      orderNumberVO.setWhereClauseParams(null); // clean up from previous invokation.

/*
      whereClause.append(" location_code in (SELECT xilv.segment1 "                                         ); // 保管倉庫コード
      whereClause.append("                   FROM fnd_user      fu "                                        ); // ユーザマスタ
      whereClause.append("                       ,per_all_people_f papf "                                   );
      whereClause.append("                       ,xxcmn_item_locations_v xilv "                             ); // OPM保管場所情報VIEW
      whereClause.append("                   WHERE fu.employee_id              = papf.person_id "           );
      whereClause.append("                     AND NVL(fu.start_date,SYSDATE) <= TRUNC(SYSDATE) "           );
      whereClause.append("                     AND NVL(fu.end_date,SYSDATE)   >= TRUNC(SYSDATE) "           );
      whereClause.append("                     AND NVL(papf.effective_start_date,SYSDATE) <= TRUNC(SYSDATE) " ); // 適用開始日
      whereClause.append("                     AND NVL(papf.effective_end_date,SYSDATE)   >= TRUNC(SYSDATE) " ); // 適用終了日
      whereClause.append("                     AND papf.ATTRIBUTE4 = xilv.PURCHASE_CODE "                   );
      whereClause.append("                     AND fu.user_id                 = FND_GLOBAL.USER_ID) "       );
*/
// 20080516 yoshimoto mod Start
// 20080528 yoshimoto add Start
      if (XxcmnUtility.isBlankOrNull(purchaseSiteCode))
      {
// 20080528 yoshimoto add End
        whereClause.append(" location_code in (SELECT xilv.segment1 "                                                 ); // 保管倉庫コード
        whereClause.append("                   FROM fnd_user      fu "                                                ); // ユーザマスタ
        whereClause.append("                       ,per_all_people_f papf "                                           );
        whereClause.append("                       ,xxcmn_item_locations_v xilv "                                     ); // OPM保管場所情報VIEW
        whereClause.append("                   WHERE  fu.employee_id               = papf.person_id "                 );
        whereClause.append("                     AND    fu.user_id                 = FND_GLOBAL.USER_ID "             );
        whereClause.append("                     AND    papf.ATTRIBUTE4            = xilv.PURCHASE_CODE "             );
        whereClause.append("                     AND    papf.effective_start_date <= TRUNC(SYSDATE) "                 ); // 適用開始日
        whereClause.append("                     AND    papf.effective_end_date   >= TRUNC(SYSDATE) "                 ); // 適用終了日
        whereClause.append("                     AND    fu.start_date             <= TRUNC(SYSDATE) "                 );
        whereClause.append("                     AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE)))) " );
// 20080528 yoshimoto add Start
      } else 
      {
        whereClause.append(" location_code in (SELECT xilv.segment1 "                                                 ); // 保管倉庫コード
        whereClause.append("                   FROM fnd_user      fu "                                                ); // ユーザマスタ
        whereClause.append("                       ,per_all_people_f papf "                                           );
        whereClause.append("                       ,xxcmn_item_locations_v xilv "                                     ); // OPM保管場所情報VIEW
        whereClause.append("                   WHERE  fu.employee_id               = papf.person_id "                 );
        whereClause.append("                     AND    fu.user_id                 = FND_GLOBAL.USER_ID "             );
        whereClause.append("                     AND    papf.attribute4            = xilv.purchase_code "             );
        whereClause.append("                     AND    papf.attribute6            = xilv.purchase_site_code "        );
        whereClause.append("                     AND    papf.effective_start_date <= TRUNC(SYSDATE) "                 ); // 適用開始日
        whereClause.append("                     AND    papf.effective_end_date   >= TRUNC(SYSDATE) "                 ); // 適用終了日
        whereClause.append("                     AND    fu.start_date             <= TRUNC(SYSDATE) "                 );
        whereClause.append("                     AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE)))) " );                
      }
// 20080528 yoshimoto add End
// 20080516 yoshimoto mod End

      orderNumberVO.setWhereClause(whereClause.toString());

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
