/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateCO
* �T�v����   : ���[�gNo/�S���c�ƈ��ꊇ�X�V��ʃR���g���[���N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-16 1.0  SCS�x���a��  �V�K�쐬
* 2010-03-23 1.1  SCS�������  [E_�{�ғ�_01942]�Ǘ������_�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso019009j.util.XxcsoRtnRsrcBulkUpdateConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * ���[�gNo/�S���c�ƈ��ꊇ�X�V��ʂ̃R���g���[���N���X
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateCO extends OAControllerImpl
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

    // �|�b�v���X�g�̏�����
    am.invokeMethod("initPopList");

// 2010-03-23 [E_�{�ғ�_01942] Add Start
    am.invokeMethod("afterProcess");
// 2010-03-23 [E_�{�ғ�_01942] Add End

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
    
    XxcsoUtils.debug(pageContext, "[START]");
    
    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    //�i�ރ{�^��������
    if ( pageContext.getParameter("SearchButton") != null )
    {
      am.invokeMethod("handleSearchButton");
    }

    //�����{�^��������
    if ( pageContext.getParameter("ClearButton") != null )
    {
      am.invokeMethod("handleClearButton");
    }

    //�ǉ��{�^��������
    if ( pageContext.getParameter("AddCustomerButton") != null )
    {
      am.invokeMethod("handleAddCustomerButton");
    }

    //�K�p�{�^��������
    if ( pageContext.getParameter("SubmitButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleSubmitButton");
      pageContext.putDialogMessage(msg);

      HashMap params = new HashMap(1);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoRtnRsrcBulkUpdateConstants.MODE_FIRE_ACTION
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_RTN_RSRC_BULK_UPDATE_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    //����{�^��������
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

// 2010-03-23 [E_�{�ғ�_01942] Add Start
    am.invokeMethod("afterProcess");
// 2010-03-23 [E_�{�ғ�_01942] Add End
    XxcsoUtils.debug(pageContext, "[END]");

  }

  /*****************************************************************************
   * ��ʃ��C�A�E�g��������
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  private void setVAlignMiddle(OAWebBean webBean)
  {
    String[] objects = XxcsoRtnRsrcBulkUpdateConstants.CENTERING_OBJECTS;
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
    webBean.findChildRecursive("SearchButton").setRendered(false);
    webBean.findChildRecursive("ClearButton").setRendered(false);
    webBean.findChildRecursive("AddCustomerButton").setRendered(false);
    webBean.findChildRecursive("SubmitButton").setRendered(false);
    webBean.findChildRecursive("CancelButton").setRendered(false);
  }
}
