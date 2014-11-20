/*============================================================================
* �t�@�C���� : XxcsoSalesPlanBulkRegistCO
* �T�v����   : ����v��(�����ڋq)�@�R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS�p�M�F�@  �V�K�쐬
* 2009-02-26 1.0  SCS�p�M�F�@  ���\�b�h�w�b�_�[�ǋL
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.webui;

import itoen.oracle.apps.xxcso.xxcso019002j.util.XxcsoSalesPlanBulkRegistConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

/*******************************************************************************
 * ����v��(�����ڋq)�@�R���g���[���N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanBulkRegistCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * ��ʋN��������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
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
    
    //Table���[�W�����̕\���s���ݒ�֐�    
    OAException oaeMsg
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"ResultAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_019_A09_01"
        );

    if ( oaeMsg != null )
    {
      pageContext.putDialogMessage(oaeMsg);
      setErrorMode(pageContext, webBean);
    }
    
    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʃC�x���g����������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

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
       ,XxcsoSalesPlanBulkRegistConstants.MODE_FIRE_ACTION
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SALES_PLAN_BULK_REGIST_PG
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
       ,XxcsoSalesPlanBulkRegistConstants.MODE_FIRE_ACTION
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SALES_PLAN_BULK_REGIST_PG
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

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʂ�VAlignMiddle�ݒ肵�܂��B
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  private void setVAlignMiddle(OAWebBean webBean)
  {
    String[] objects = XxcsoSalesPlanBulkRegistConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);

      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("middle");
      }
    }
  }

  /*****************************************************************************
   * ��ʂ��G���[���[�h�ɐݒ肵�܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  private void setErrorMode(OAPageContext pageContext, OAWebBean webBean)
  {
  }
}
