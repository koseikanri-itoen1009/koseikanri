/*============================================================================
* �t�@�C���� : XxwshReserveLotInputCO
* �T�v����   : ���������b�g���͉�ʃR���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-17 1.0  �k����   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jbo.domain.Date;

/***************************************************************************
 * ���������b�g���͉�ʃR���g���[���N���X�ł��B
 * @author  ORACLE �k���� ���v
 * @version 1.0
 ***************************************************************************
 */
public class XxwshReserveLotInputCO extends XxcmnOAControllerImpl
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
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // AM�̎擾(�_�C�A���O��ʂ�YES�{�^�����������ꂽ�ꍇ�g�p���邽�߂����Ŏ擾)
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // �ꊇ�����{�^�����������ꂽ�ꍇ
      if (pageContext.getParameter("Cancel") != null)
      {
        // �������s��Ȃ��B

      // �v�Z�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Calc") != null)
      {
        // �������s��Ȃ�

      // �K�p�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Apply") != null)
      {
        // �������s��Ȃ�

      // �x���w����ʂɖ߂�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Return") != null)
      {
        // �������s��Ȃ�

      // �_�C�A���O��ʂ�NO�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("No") != null)
      {
        //No�{�^�����������i���b�N�������������s)
        am.invokeMethod("noBtn");

      // �_�C�A���O��ʂ�YES�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Yes") != null)
      {
        // �o�^����
        am.invokeMethod("yesBtn");
        
      // �����\���̏ꍇ
      } else
      {
        // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
        TransactionUnitHelper.startTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920002J);

        // �p�����[�^�擾      
        HashMap searchParams = new HashMap();
        searchParams.put("LineId",           pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID));           // �󒍖��׃A�h�I��ID
        searchParams.put("callPictureKbn",   pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN));  // �ďo��ʋ敪
        searchParams.put("headerUpdateDate", pageContext.getParameter(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE));// �w�b�_�X�V����
        searchParams.put("lineUpdateDate",   pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE));  // ���׍X�V����
        searchParams.put("exeKbn",           pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN));           // �N���敪
        // �����ݒ�
        Serializable params[] = { searchParams };
        // �����^�ݒ�
        Class[] parameterTypes = { HashMap.class };
        // �����������s
        am.invokeMethod("initialize", params, parameterTypes);
      }
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwshConstants.TXN_XXWSH920002J, true))
      { 
      // �y���ʏ����z�G���[�_�C�A���O��ʂ֑J��
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
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

    try
    {     
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
     
      // �x���w����ʂ֖߂�{�^�����������ꂽ�ꍇ
      if (pageContext.getParameter("Return") != null) 
      {
        String callPictureKbn = pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN); // �ďo��ʋ敪
        String exeKbn         = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);          // �N���敪
        String url            = XxpoConstants.URL_XXPO440001JL;                                      // �x���w���쐬���׉��

        // �˗�No�擾
        Serializable params[] = { pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID) };
        String reqNo          = (String)am.invokeMethod("getReqNo"); // �˗�No
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,  exeKbn); // �N���敪
        pageParams.put(XxwshConstants.URL_PARAM_REQ_NO,   reqNo);  // �˗�No

        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920002J);
          
        // �x���w����ʂ�
        pageContext.setForwardURL(
          url,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // �ꊇ�����{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Cancel") != null))    
      {
        // �ꊇ�����������s
        am.invokeMethod("cancelBtn");

      // �v�Z�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Calc") != null))    
      {
        // �v�Z�������s
        am.invokeMethod("calcBtn");
      // �K�p�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Apply") != null)
      {
        // �K�p�{�^�����������s
        am.invokeMethod("applyBtn");
       
        /*****************************************/
        /*    �x���`�F�b�N����                     */
        /*****************************************/
        HashMap msg = (HashMap)am.invokeMethod("checkWarning");
        // �擾�����ϐ����i�[
        String[] lotRevErrFlg   = (String[])msg.get("lotRevErrFlg");                       // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
        String[] freshErrFlg    = (String[])msg.get("freshErrFlg");                        // �N�x�����`�F�b�N�G���[�t���O
        String[] shortageErrFlg = (String[])msg.get("shortageErrFlg");                     // �����\�݌ɐ������`�F�b�N�G���[�t���O
        String[] exceedErrFlg   = (String[])msg.get("exceedErrFlg");                       // �����\�݌ɐ����߃`�F�b�N�G���[�t���O
        String[] lotNo          = (String[])msg.get("lotNo");                              // ���b�gNo
        Date[] revDate          = (Date[])msg.get("revDate");                              // �t�]���t
        Date[] standardDate     = (Date[])msg.get("standardDate");                         // ���
        String[] shipType       = (String[])msg.get("shipType");                           // ShipType
        String[] itemShortName  = (String[])msg.get("itemShortName");                      // �i�ږ�
        String[] deliverTo      = (String[])msg.get("deliverTo");                          // �o�ɐ�
        String[] locationName   = (String[])msg.get("locationName");                       // �o�Ɍ��ۊǏꏊ
        

        // �_�C�A���O��ʕ\���p���b�Z�[�W
        StringBuffer pageHeaderText = new StringBuffer(100);

        // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O�̌��������[�v���s
        for (int i = 0 ; i < lotRevErrFlg.length ; i++)
        {
          // ���b�g�t�]�h�~�`�F�b�N�ŃG���[�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(lotRevErrFlg[i]))
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(pageHeaderText);

            // ���b�g�t�]�h�~�x�����b�Z�[�W�擾
            MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_ITEM,     itemShortName[i]),
                                      new MessageToken(XxwshConstants.TOKEN_LOT,      lotNo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_SHIP_TYPE,shipType[i]),
                                      new MessageToken(XxwshConstants.TOKEN_LOCATION, deliverTo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_ARRIVAL_DATE,  XxcmnUtility.stringValue(revDate[i]))};
            pageHeaderText.append(
              pageContext.getMessage(
              XxcmnConstants.APPL_XXWSH, 
              XxwshConstants.XXWSH32901,
              tokens));
          }

          // �N�x�����`�F�b�N�ŃG���[�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(freshErrFlg[i]))
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(pageHeaderText);

            // ���b�g�t�]�h�~�x�����b�Z�[�W�擾
            MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_LOT,      lotNo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_SHIP_TO,  deliverTo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_ARRIVAL_DATE,  XxcmnUtility.stringValue(standardDate[i]))};
            pageHeaderText.append(
              pageContext.getMessage(
              XxcmnConstants.APPL_XXWSH, 
              XxwshConstants.XXWSH32902,
              tokens));
          }

          // �����\�݌ɐ������`�F�b�N�ŃG���[�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(shortageErrFlg[i]))
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(pageHeaderText);

            // �����\�݌ɐ������`�F�b�N�x�����b�Z�[�W�擾
            MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_LOCATION, locationName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_ITEM,  itemShortName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_LOT,   lotNo[i])};
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXCMN, 
                XxcmnConstants.XXCMN10112,
                tokens));
          }

          // �����\�݌ɐ����߃`�F�b�N�ŃG���[�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(exceedErrFlg[i]))
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(pageHeaderText);

            // �����\�݌ɐ����߃`�F�b�N�x�����b�Z�[�W�擾
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_LOCATION,  locationName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_ITEM,      itemShortName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_LOT,       lotNo[i])};
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXCMN, 
                XxcmnConstants.XXCMN10110,
                tokens));
          }
        }

        // �x�����b�Z�[�W�̂���ꍇ�A�_�C�A���O��\��
        if (pageHeaderText.length() > 0)
        {
          // ���C�����b�Z�[�W�쐬 
          MessageToken[] mainTokens = new MessageToken[1];
          mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, pageHeaderText.toString());

          OAException mainMessage = new OAException(
                                          XxcmnConstants.APPL_XXCMN,
                                          XxcmnConstants.XXCMN00025,
                                          mainTokens);
                                            
          // �_�C�A���O���b�Z�[�W��\��
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxwshConstants.URL_XXWSH920002JH,
            XxwshConstants.URL_XXWSH920002JH,
            "Yes",
            "No",
            "Yes",
            "No",
            null);          
        }
        // �o�^����
        am.invokeMethod("yesBtn");
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }

}
