/*============================================================================
* �t�@�C���� : XxcsoPvRegistCO
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʃR���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonUtils;

import java.io.Serializable;

import java.util.ArrayList;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;


/*******************************************************************************
 * �p�[�\�i���C�Y�r���[�쐬��ʂ̃R���g���[���N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvRegistCO extends OAControllerImpl
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

    Boolean returnValue = Boolean.TRUE;

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URL����p�����[�^���擾���܂��B
    String execMode
      =  pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // �����\���p�����̐ݒ�
    Serializable[] params = { viewId, pvDisplayMode };
    // **********************
    // ���s�敪�ɂ�菈������
    // **********************
    // �V�K�쐬***************
    if ( XxcsoPvCommonConstants.EXECUTE_MODE_CREATE.equals(execMode) )
    {      
      am.invokeMethod("initCreateDetails", params);
    }
    // ����***************
    else if ( XxcsoPvCommonConstants.EXECUTE_MODE_COPY.equals(execMode) )
    {
      returnValue = (Boolean) am.invokeMethod("initCopyDetails", params);
    }
    // �X�V***************
    else if ( XxcsoPvCommonConstants.EXECUTE_MODE_UPDATE.equals(execMode) )
    {
      returnValue = (Boolean) am.invokeMethod("initUpdateDetails", params);
    }
    // ��L�ȊO�̓G���[���[�h�Ƃ���
    else
    {
      returnValue = Boolean.FALSE;
    }

    // �����\���ݒ��Ԃɂ��G���[���[�h�ݒ�
    if ( !returnValue.booleanValue() )
    {
      this.setErrorMode(pageContext, webBean);
    }

    // ****************************************
    // *****�v���t�@�C���E�I�v�V�����̐ݒ�*****
    // ****************************************
    boolean errorMode = false;

    // **FND: �r���[�E�I�u�W�F�N�g�ő�t�F�b�`�E�T�C�Y�̐ݒ�
    OAException oaeMsg =
      XxcsoUtils.setAdvancedTableRows(
        pageContext
        ,webBean
        ,XxcsoPvCommonConstants.EXTRACT_CONDITION_ADV_TBL_RN
        ,XxcsoConstants.VO_MAX_FETCH_SIZE
      );
    if (oaeMsg != null)
    {
      pageContext.putDialogMessage(oaeMsg);
      errorMode = true;
    }

    if ( errorMode )
    {
      this.setErrorMode(pageContext, webBean);
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

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // �ėp�����\���敪
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u����v�{�^��
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // �p�[�\�i���C�Y�r���[�\����ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    // �u�K�p����ь������s�v�{�^��
    if ( pageContext.getParameter("AppliAndSearchButton") != null )
    {
      // AM�Ăяo���̈����𐶐�
      ArrayList trailingList = this.getTrailingListValues(pageContext, webBean);
      Serializable[] params    = { trailingList };
      Class[]        paramType = { ArrayList.class };

      // AM�̎��s
      // �o�^�^�����^�X�V�Ώۂ�viewID���擾����
      String targetViewId
        = (String)
            am.invokeMethod("handleAppliAndSearchButton", params, paramType);

      // ���b�Z�[�W
      OAException msg = (OAException)am.invokeMethod("getMessage");
      // �J�ڐ��ʂւ̃��b�Z�[�W�̐ݒ�
      XxcsoUtils.setDialogMessage(pageContext, msg);

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_QUERY
           ,pvDisplayMode
           ,targetViewId
          );

      // �������ėp�����\����ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // �u�K�p�v�{�^��
    if ( pageContext.getParameter("ApplicationButton") != null )
    {
      // AM�Ăяo���̈����𐶐�
      ArrayList trailingList = this.getTrailingListValues(pageContext, webBean);
      Serializable[] params    = { trailingList };
      Class[]        paramType = { ArrayList.class };

      am.invokeMethod("handleApplicationButton", params, paramType);

      // ���b�Z�[�W�̎擾
      OAException msg = (OAException)am.invokeMethod("getMessage");
      // �J�ڐ��ʂւ̃��b�Z�[�W�̐ݒ�
      XxcsoUtils.setDialogMessage(pageContext, msg);

      // URL�p�����[�^�̍쐬
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // �������ėp�����\����ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // �u�ǉ��v�{�^��
    if ( pageContext.getParameter("AddtionButton") != null )
    {
      am.invokeMethod("handleAddtionButton");
    }

    // �u�폜�v�{�^��
    if ( pageContext.getParameter("DeleteButton") != null )
    {
      am.invokeMethod("handleDeleteButton");
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
    webBean.findChildRecursive("AppliAndSearchButton").setRendered(false);
    webBean.findChildRecursive("Spacer").setRendered(false);
    webBean.findChildRecursive("ApplicationButton").setRendered(false);
    webBean.findChildRecursive("MainSlRN").setRendered(false);
  }

  /*****************************************************************************
   * shuttle���[�W������trailing�̒l���擾���܂��B
   * @param  pageContext �y�[�W�R���e�L�X�g
   * @param  webBean     ��ʏ��
   * @return trailing��value�l(��ʂőI�����ꂽ����)
   *****************************************************************************
   */
  private ArrayList getTrailingListValues(
    OAPageContext pageContext
    ,OAWebBean webBean
  )
  {
    String value = pageContext.getParameter("LineOrderStlRN:trailing:items");
    String[] valArr = value.split(";");
    ArrayList list = new ArrayList(200);
    for (int i = 0; i < valArr.length; i++)
    {
      // 0�������l����null�E�󕶎��`�F�b�N
      if (valArr[i] != null && !"".equals(valArr[i])) 
      {
        list.add(valArr[i]);
      }
    }

    return list;
  }

}
