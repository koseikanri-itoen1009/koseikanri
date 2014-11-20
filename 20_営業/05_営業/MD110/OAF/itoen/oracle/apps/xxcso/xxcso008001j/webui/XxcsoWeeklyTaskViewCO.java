/*============================================================================
* �t�@�C���� : XxcsoWeeklyTaskViewCO
* �T�v����   : �T�������󋵏Ɖ�R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-07 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.webui;

import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso008001j.util.XxcsoWeeklyTaskViewConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;

/*******************************************************************************
 * �T�������󋵏Ɖ��ʂ̃R���g���[���N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoWeeklyTaskViewCO extends OAControllerImpl
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
    super.processRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");

    // �o�^�n�����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    String executeMode = pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String txnKey1 = pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);

    Serializable[] params =
    {
      txnKey1
    };
    
    if ( XxcsoWeeklyTaskViewConstants.MODE_TRANSFER.equals(executeMode) )
    {
      am.invokeMethod("initAfterHandleShowButton", params);
    }
    else
    {
      // �����\���������s
      am.invokeMethod("initDetails");
    }

    // ****************************************
    // *****�v���t�@�C���E�I�v�V�����̐ݒ�*****
    // ****************************************
    // ���[�W�������i�[�p�z��
    String[] regionAdvTbl =
    {
      XxcsoWeeklyTaskViewConstants.RN_EMP_SEL_ADV_TBL
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "01"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "02"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "03"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "04"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "05"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "06"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "07"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "08"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "09"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "10"
    };

    boolean errorMode = false;
    OAException oaeMsg = null;

    // **FND: �r���[�E�I�u�W�F�N�g�ő�t�F�b�`�E�T�C�Y�̐ݒ�
    for (int i = 0; i < regionAdvTbl.length; i++)
    {
      oaeMsg =
        XxcsoUtils.setAdvancedTableRows(
          pageContext
          ,webBean
          ,regionAdvTbl[i]
          ,XxcsoConstants.VO_MAX_FETCH_SIZE
        );
      if (oaeMsg != null)
      {
        pageContext.putDialogMessage(oaeMsg);
        errorMode = true;
        break;
      }
    }

    // �G���[���[�h�ݒ�
    if (errorMode)
    {
      webBean.findChildRecursive("MainSlRN").setRendered(false);
    }

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
    super.processFormRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u�߂�v�{�^��
    if ( pageContext.getParameter("BackButton") != null )
    {
      // ���j���[��ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,null
        ,true
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    // �u�i�ށv�{�^��
    if ( pageContext.getParameter("ForwardButton") != null )
    {
      am.invokeMethod("handleForwardButton");
    }

    // �uCSV�쐬�v�{�^��
    if ( pageContext.getParameter("CsvCreateButton") != null )
    {

      am.invokeMethod("handleCsvCreateButton");

      OAException msg = (OAException)am.invokeMethod("getMessage");
      pageContext.putDialogMessage(msg);

    }

    // �u�\���v�{�^��
    if ( pageContext.getParameter("ShowButton") != null )
    {
      String urlParam = (String)am.invokeMethod("handleShowButton");
      
      HashMap params = new HashMap(2);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoWeeklyTaskViewConstants.MODE_TRANSFER
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,urlParam
      );

      // AM�ێ���false�Ŏ���ʑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_WEEKLY_TASK_VIEW_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
      
    }

    // ************************************
    // *****Link�����n���h�����O***********
    // ************************************
    if ( "TaskClick".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)) )
    {
      
      String taskId = pageContext.getParameter("SelectedTaskId");
      String taskOwnerId = pageContext.getParameter("SelectedTaskOwnerId");

      // ���O�C�����[�U�[�̃��\�[�XID�擾
      String loginResourceId = (String)am.invokeMethod("getLoginResourceId");

      XxcsoUtils.debug(pageContext, "taskId=[" + taskId + "]");
      XxcsoUtils.debug(pageContext, "taskOwnerId=[" + taskOwnerId + "]");
      XxcsoUtils.debug(pageContext, "loginResourceId=[" + loginResourceId + "]");

      // URL�p�����[�^�̍쐬
      HashMap paramMap = new HashMap();
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_TASK_ID
        ,pageContext.encrypt(taskId)
      );
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_TASK_RETURN_URL
        ,pageContext.getCurrentUrlForRedirect()
      );
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_RETURN_LABEL
       ,XxcsoWeeklyTaskViewConstants.PARAM_VALUE_RETURN_LABEL
      );
      
      // �X�V�E�Q�ƃ��[�h�̐ݒ�
      // ���\�[�XID����v���Ȃ��ꍇ�̂�cacTaskUsrAuth��ݒ�
      // ���l��TaskSumm�Ɠ��l��"1"��ݒ�
      if ( !loginResourceId.equals(taskOwnerId) )
      {
        paramMap.put(
          XxcsoWeeklyTaskViewConstants.PARAM_TASK_USER_AUTH
          ,pageContext.encrypt("1")
        );
      }
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_BASE_PAGE_REGION_CODE
        ,"/oracle/apps/jtf/cac/task/webui/TaskUpdatePG"
      );

      // �^�X�N��ʂ֑J��
      pageContext.setForwardURL(
        XxcsoConstants.FUNC_TASK_UPDATE_PG
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,paramMap
        ,false
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        ,(byte) 99
      );

    }

    XxcsoUtils.debug(pageContext, "[END]");

  }

}
