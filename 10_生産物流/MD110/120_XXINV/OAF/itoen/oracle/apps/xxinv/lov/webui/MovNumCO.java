/*============================================================================
* �t�@�C���� : MovNumCO
* �T�v����   : �ړ��ԍ��R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  �勴�F�Y     �V�K�쐬
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
 * �ړ��ԍ��R���g���[���N���X�ł��B
 * @author  ORACLE �勴 �F�Y
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
    
    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("MovNumVO1");
    vo.setWhereClause (null);
    vo.setWhereClauseParams (null);
    vo.setWhereClauseParam(0, productFlg);

    // �O�����[�U�̏ꍇ
    if (XxinvConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      // ���̓p�����[�^���уf�[�^�敪��1(�o�Ɏ���)���o�Ɍ�ID�����͂���Ă����ꍇ
      if ((!XxcmnUtility.isBlankOrNull(shippedLocatId)) && ("1".equals(actualFlg)))
      {
        vo.setWhereClause(" shipped_locat_id = :2");
        vo.setWhereClauseParam(1, shippedLocatId);


      // ���̓p�����[�^���уf�[�^�敪��2(���Ɏ���)�����ɐ�ID�����͂���Ă����ꍇ
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
