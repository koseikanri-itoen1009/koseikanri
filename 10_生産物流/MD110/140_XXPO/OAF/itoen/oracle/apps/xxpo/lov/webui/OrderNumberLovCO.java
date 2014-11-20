/*============================================================================
* �t�@�C���� : OrderNumberLovCO
* �T�v����   : ����No���X�g�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-13 1.0  �g������     �V�K�쐬
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
 * ����No���X�g�R���g���[���ł��B
 * @author  SCS �g�� ����
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

    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    Dictionary passiveCriteriaItems = pageContext.getLovCriteriaItems();

    // �]�ƈ��敪
    String peopleCode = null;
// 20080528 yoshimoto add Start
    // �d����T�C�g�R�[�h
    String purchaseSiteCode = null;
// 20080528 yoshimoto add End

    if (!XxcmnUtility.isBlankOrNull(passiveCriteriaItems.get("PeopleCode"))) 
    {
      peopleCode = (String)passiveCriteriaItems.get("PeopleCode");
// 20080528 yoshimoto add Start
      purchaseSiteCode = (String)passiveCriteriaItems.get("PurchaseSiteCode");
// 20080528 yoshimoto add End
    }

    // �]�ƈ��敪��2:�O���̏ꍇ�A�w�[���� = ���q�Ɂx��ǉ�
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {

      StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g

      // ����NoVO���擾
      OAViewObject orderNumberVO = (OAViewObject)am.findViewObject("OrderNumberVO1");

      // ������
      orderNumberVO.setWhereClause(null);       // clean up from previous invokation
      orderNumberVO.setWhereClauseParams(null); // clean up from previous invokation.

/*
      whereClause.append(" location_code in (SELECT xilv.segment1 "                                         ); // �ۊǑq�ɃR�[�h
      whereClause.append("                   FROM fnd_user      fu "                                        ); // ���[�U�}�X�^
      whereClause.append("                       ,per_all_people_f papf "                                   );
      whereClause.append("                       ,xxcmn_item_locations_v xilv "                             ); // OPM�ۊǏꏊ���VIEW
      whereClause.append("                   WHERE fu.employee_id              = papf.person_id "           );
      whereClause.append("                     AND NVL(fu.start_date,SYSDATE) <= TRUNC(SYSDATE) "           );
      whereClause.append("                     AND NVL(fu.end_date,SYSDATE)   >= TRUNC(SYSDATE) "           );
      whereClause.append("                     AND NVL(papf.effective_start_date,SYSDATE) <= TRUNC(SYSDATE) " ); // �K�p�J�n��
      whereClause.append("                     AND NVL(papf.effective_end_date,SYSDATE)   >= TRUNC(SYSDATE) " ); // �K�p�I����
      whereClause.append("                     AND papf.ATTRIBUTE4 = xilv.PURCHASE_CODE "                   );
      whereClause.append("                     AND fu.user_id                 = FND_GLOBAL.USER_ID) "       );
*/
// 20080516 yoshimoto mod Start
// 20080528 yoshimoto add Start
      if (XxcmnUtility.isBlankOrNull(purchaseSiteCode))
      {
// 20080528 yoshimoto add End
        whereClause.append(" location_code in (SELECT xilv.segment1 "                                                 ); // �ۊǑq�ɃR�[�h
        whereClause.append("                   FROM fnd_user      fu "                                                ); // ���[�U�}�X�^
        whereClause.append("                       ,per_all_people_f papf "                                           );
        whereClause.append("                       ,xxcmn_item_locations_v xilv "                                     ); // OPM�ۊǏꏊ���VIEW
        whereClause.append("                   WHERE  fu.employee_id               = papf.person_id "                 );
        whereClause.append("                     AND    fu.user_id                 = FND_GLOBAL.USER_ID "             );
        whereClause.append("                     AND    papf.ATTRIBUTE4            = xilv.PURCHASE_CODE "             );
        whereClause.append("                     AND    papf.effective_start_date <= TRUNC(SYSDATE) "                 ); // �K�p�J�n��
        whereClause.append("                     AND    papf.effective_end_date   >= TRUNC(SYSDATE) "                 ); // �K�p�I����
        whereClause.append("                     AND    fu.start_date             <= TRUNC(SYSDATE) "                 );
        whereClause.append("                     AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE)))) " );
// 20080528 yoshimoto add Start
      } else 
      {
        whereClause.append(" location_code in (SELECT xilv.segment1 "                                                 ); // �ۊǑq�ɃR�[�h
        whereClause.append("                   FROM fnd_user      fu "                                                ); // ���[�U�}�X�^
        whereClause.append("                       ,per_all_people_f papf "                                           );
        whereClause.append("                       ,xxcmn_item_locations_v xilv "                                     ); // OPM�ۊǏꏊ���VIEW
        whereClause.append("                   WHERE  fu.employee_id               = papf.person_id "                 );
        whereClause.append("                     AND    fu.user_id                 = FND_GLOBAL.USER_ID "             );
        whereClause.append("                     AND    papf.attribute4            = xilv.purchase_code "             );
        whereClause.append("                     AND    papf.attribute6            = xilv.purchase_site_code "        );
        whereClause.append("                     AND    papf.effective_start_date <= TRUNC(SYSDATE) "                 ); // �K�p�J�n��
        whereClause.append("                     AND    papf.effective_end_date   >= TRUNC(SYSDATE) "                 ); // �K�p�I����
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
