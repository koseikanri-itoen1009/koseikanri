/*============================================================================
* �t�@�C���� : MovNumCO
* �T�v����   : �i�ڃR���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-04 1.0  �勴�F�Y     �V�K�쐬
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
 * �i�ڃR���g���[���N���X�ł��B
 * @author  ORACLE �勴 �F�Y
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

    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("ItemCodeVO1");
    vo.setWhereClause (null);
    vo.setWhereClauseParams (null);

    StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g

    // ���i���ʋ敪���P�̏ꍇ
    if ("1".equals(productFlg))
    {
      whereClause.append(" item_class_code = :1");
      vo.setWhereClauseParam(0, XxinvConstants.ITEM_CLASS_5);
    // ���i���ʋ敪���Q�̏ꍇ
    } else if ("2".equals(productFlg))
    {
      whereClause.append(" item_class_code != :1");
      vo.setWhereClauseParam(0, XxinvConstants.ITEM_CLASS_5);
    }

    // �d�ʗe�ϋ敪�����͂���Ă����ꍇ
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
