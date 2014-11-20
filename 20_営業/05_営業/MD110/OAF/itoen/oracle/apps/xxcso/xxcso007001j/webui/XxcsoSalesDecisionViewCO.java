/*============================================================================
* �t�@�C���� : XxcsoSalesDecisionViewCO
* �T�v����   : ���k������\���R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-08 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007001j.webui;

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

/*******************************************************************************
 * ���k������\����ʂ̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesDecisionViewCO extends OAControllerImpl
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
    String leadId = pageContext.getParameter("ASNReqFrmOpptyId");
    if(leadId == null || "".equals(leadId))
        leadId = pageContext.getParameter("PRPObjectId");
    if(leadId == null)
    {
      leadId = (String)pageContext.getTransactionValue("ASNTxnOppId");
    }
    
    XxcsoUtils.debug(pageContext, "lead_id = " + leadId);
    if (leadId == null || "".equals(leadId))
    {
      XxcsoUtils.debug(pageContext, "Transaction key not exist");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AM�֓n���������쐬���܂��B
    Serializable[] params =
    {
      leadId
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

    OAException error
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"XxcsoSalesDecisionAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_007_A01_01"
        );

    if ( error != null )
    {
      pageContext.putDialogMessage(error);
      OAWebBean bean = null;
      bean = webBean.findChildRecursive("MainSlRN");
      bean.setRendered(false);
    }

    // �y�[�W�ԃ��b�Z�[�W�\��
    XxcsoUtils.showDialogMessage(pageContext);

    OAMessageTextInputBean bean = null;
    bean
      = (OAMessageTextInputBean)
          webBean.findChildRecursive("XxcsoOtherContent");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);
    
    bean
      = (OAMessageTextInputBean)
          webBean.findChildRecursive("XxcsoIntroduceTerms");
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

    if ( pageContext.getParameter("XxcsoForwardButton") != null )
    {
      HashMap params = (HashMap)am.invokeMethod("handleForwardButton");
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SALES_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }
}
