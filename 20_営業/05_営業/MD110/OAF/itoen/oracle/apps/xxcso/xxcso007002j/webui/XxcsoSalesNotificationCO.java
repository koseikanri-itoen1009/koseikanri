/*============================================================================
* �t�@�C���� : XxcsoSalesNotificationCO
* �T�v����   : ���k������ʒm�R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-08 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007002j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.OAException;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;

/*******************************************************************************
 * ���k������ʒm��ʂ̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotificationCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * ��ʋN�����̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    super.processRequest(pageContext, webBean);

    // URL����p�����[�^���擾���܂��B
    String mode     = pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String notifyId = pageContext.getParameter("NtfId");
    XxcsoUtils.debug(pageContext, "mode  = " + mode);
    if (mode == null || "".equals(mode))
    {
      XxcsoUtils.debug(pageContext, "Execute Mode not exist");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    XxcsoUtils.debug(pageContext, "NtfId = " + notifyId);
    if (notifyId == null || "".equals(notifyId))
    {
      XxcsoUtils.debug(pageContext, "Transaction key not exist");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AM�֓n���������쐬���܂��B
    Serializable[] params =
    {
      mode
     ,notifyId
    };

    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }
    
    // �������ɐݒ肵�����\�b�h���̃��\�b�h��Call���܂��B
    am.invokeMethod("initDetails", params);

    ArrayList errorList = new ArrayList();
    OAException error = null;

    error
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"SalesDecisionInfoAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_007_A02_01"
        );

    if ( error != null )
    {
      errorList.add(error);
    }
    
    error
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"NotifyListAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_007_A02_02"
        );

    if ( error != null )
    {
      errorList.add(error);
    }

    if ( errorList.size() > 0 )
    {
      error = OAException.getBundledOAException(errorList);
      pageContext.putDialogMessage(error);
      OAWebBean bean = null;
      bean = webBean.findChildRecursive("MainTlRN");
      bean.setRendered(false);
    }
    
    OAMessageTextInputBean bean = null;
    bean
      = (OAMessageTextInputBean)webBean.findChildRecursive("OtherContent");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);
    
    bean
      = (OAMessageTextInputBean)webBean.findChildRecursive("NotifyComment");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);
    
    bean
      = (OAMessageTextInputBean)webBean.findChildRecursive("ApprRjctComment");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);
    
    bean
      = (OAMessageTextInputBean)webBean.findChildRecursive("IntroduceTerms");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʃC�x���g�̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    super.processFormRequest(pageContext, webBean);

    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
    XxcsoUtils.debug(pageContext, "event = " + event);
    
    if ( "SelectLeadDescriptionLink".equals(event) )
    {
      HashMap params
        = (HashMap)am.invokeMethod("handleSelectLeadDescriptionLink");
      
      pageContext.forwardImmediately(
        XxcsoConstants.ASN_OPPTYDETPG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,XxcsoConstants.ASN_MAIN_MENU
       ,params
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }
}
