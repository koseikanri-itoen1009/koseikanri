/*============================================================================
* �t�@�C���� : ItemNoLovCO
* �T�v����   : �i�ڒl���X�g�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-28 1.0  ��r���     �V�K�쐬
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
 * �i�ڒl���X�g�R���g���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.0
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
    
    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("ItemNoVO1");
    vo.setWhereClause (null); // clean up from previous invokation
    vo.setWhereClauseParams (null); // clean up from previous invokation.
    vo.setWhereClauseParam(0, invLocId);
    if ("1".equals(destinationType)) 
    {
      StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
      whereClause.append(" destination_type = '1' "); // �d���敪
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
