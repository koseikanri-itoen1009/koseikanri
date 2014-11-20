/*============================================================================
* �t�@�C���� : XxcsoAcctMonthlyPlanFullVOImpl
* �T�v����   : �K��E����v���ʁ@�R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAApplicationModule;
import itoen.oracle.apps.xxcso.xxcso019001j.util.XxcsoVisitSalesPlanConstants;
import java.io.Serializable;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;

/*******************************************************************************
 * �K��E����v���ʁ@�R���g���[���N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoVisitSalesPlanRegistCO extends OAControllerImpl
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

    XxcsoUtils.debug(pageContext, "[START]");

    // �o�^�n�����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URL�p�����[�^�����s���[�h���擾
    String mode = pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);

    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    Serializable[] params =
    {
      mode
    };
    
    // �������ɐݒ肵�����\�b�h���̃��\�b�h��Call���܂��B
    am.invokeMethod("initDetails", params);

    // ���C�A�E�g����
    setVAlignMiddle(webBean);
    
    XxcsoUtils.debug(pageContext, "[END]");
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

    XxcsoUtils.debug(pageContext, "[START]");
    
    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }
    
    if ( pageContext.getParameter("SearchButton") != null )
    {
      am.invokeMethod("handleSearchButton");

      HashMap params = new HashMap(1);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoVisitSalesPlanConstants.MODE_FIRE_ACTION
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_VISIT_SALES_PLAN_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    if ( pageContext.getParameter("SubmitButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleSubmitButton");
      pageContext.putDialogMessage(msg);

      HashMap params = new HashMap(1);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoVisitSalesPlanConstants.MODE_FIRE_ACTION
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_VISIT_SALES_PLAN_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,null
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    if ( "TargetMonthSalesPlanAmtChange".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)
         )
       )
    {
      am.invokeMethod("handleTargetMonthSalesPlanAmtChange");
    }

    XxcsoUtils.debug(pageContext, "[END]");

  }

  private void setVAlignMiddle(OAWebBean webBean)
  {
    String[] objects = XxcsoVisitSalesPlanConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);

      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("middle");
      }
    }
  }
}
