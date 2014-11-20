/*============================================================================
* �t�@�C���� : XxcsoInstallBasePvSearchAMImpl
* �T�v����   : �������ėp������ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

import java.util.List;
import java.util.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVORowImpl;


/*******************************************************************************
 * �������ėp������ʃA�v���P�[�V�����E���W���[���N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvSearchAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBasePvSearchAMImpl()
  {
  }

  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * ���b�Z�[�W���擾���܂��B
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * �����\������
   *****************************************************************************
   */
  public void initDetails()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �ėp�����e�[�u�� �r���[���擾�pVO
    XxcsoInstallBasePvDesignVOImpl pvDesignVo = getInstallBasePvDesignVO();
    if ( pvDesignVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvDesignVOImpl");
    }
    pvDesignVo.executeQuery();


    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �����\��(����)
   * @param viewId �r���[ID
   *****************************************************************************
   */
  public void initQueryDetails(String viewId)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �ėp�����e�[�u�� �r���[���擾�pVO
    // �\���p�Ƀv���_�E���̒l��ݒ肷��
    XxcsoInstallBasePvDesignVOImpl pvDesignVo = getInstallBasePvDesignVO();
    if ( pvDesignVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvDesignVOImpl");
    }
    pvDesignVo.executeQuery();

    XxcsoInstallBasePvDesignVORowImpl pvDesignVoRow
      = (XxcsoInstallBasePvDesignVORowImpl) pvDesignVo.first();
    if (pvDesignVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBasePvDesignVORowImpl"
        );
    }
    
    pvDesignVoRow.setSelectView(new Number(Integer.parseInt(viewId)));

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �i�ރ{�^������������
   * @return �|�b�v���X�g�őI�����ꂽ�r���[ID
   * @throw OAException
   *****************************************************************************
   */
  public String handleForwardButton()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �r���[���I���`�F�b�N����
    String viewId = this.chkViewName(true);

    XxcsoUtils.debug(txt, "[END]");

    return viewId;

  }

  /*****************************************************************************
   * �p�[�\�i���C�Y�{�^������������
   * @return �|�b�v���X�g�őI�����ꂽ�r���[ID
   * @throw OAException
   *****************************************************************************
   */
  public String handlePersonalizeButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �r���[���I���`�F�b�N����
    String viewId = this.chkViewName(false);

    XxcsoUtils.debug(txt, "[END]");

    return viewId;
  }

  /*****************************************************************************
   * �������ėp���� �\�����擾����
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����\���敪
   *****************************************************************************
   */
  public List getInstallBaseData(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �v���t�@�C�� FND:�r���[�E�I�u�W�F�N�g�ő�t�F�b�`�T�C�Y�̎擾
    String maxFetchSize = txt.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxFetchSize == null || "".equals(maxFetchSize.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    // ���o�����̎擾
    String extractTerm = this.getExtractTerm(viewId, pvDisplayMode);
    // �\�[�g�ݒ�����̎擾
    String sortColumn = this.getSortColumn(viewId, pvDisplayMode);
    // �\����̎擾
    List viewList = this.getViewColumnList(viewId, pvDisplayMode);

    // **********************************
    // ���o�����A�\�[�g������p���ĕ����ėp����VO�̎��s
    // **********************************
    XxcsoInstallBasePvSumVOImpl instBaseVo = getInstallBasePvSumVO();
    if ( instBaseVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvSumVOImpl");
    }
    // �������������s
    instBaseVo.initQuery(
      extractTerm
     ,sortColumn
    );
    int searchSize = instBaseVo.getRowCount();

    // �v���t�@�C���̍ő�t�F�b�`�T�C�Y�ƌ������ʂ̔�r
    if ( searchSize > Integer.parseInt(maxFetchSize) )
    {
      // �����Ă���ꍇ�͌x�����b�Z�[�W��ݒ肷��
      mMessage
        = XxcsoMessage.createWarningMessage(
             XxcsoConstants.APP_XXCSO1_00479
            ,XxcsoConstants.TOKEN_MAX_SIZE
            ,maxFetchSize
          );
    }

    XxcsoUtils.debug(txt, "[END]");

    return viewList;

  }

  /*****************************************************************************
   * �\���s���擾����
   * @param viewId        �r���[ID
   *****************************************************************************
   */
  public String getViewSize(String viewId)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoInstallBaseViewSizeVOImpl viewSizeVo = getInstallBaseViewSizeVO();
    if (viewSizeVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBaseViewSizeVOImpl"
        );
    }
    viewSizeVo.initQuery(viewId);

    XxcsoInstallBaseViewSizeVORowImpl viewSizeVoRow
      = (XxcsoInstallBaseViewSizeVORowImpl) viewSizeVo.first();
    if (viewSizeVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBaseViewSizeVORowImpl"
        );
    }
    XxcsoUtils.debug(txt, "[END]");

    return viewSizeVoRow.getViewSize();
  }

  /*****************************************************************************
   * �r���[���`�F�b�N����
   * @param isChecked �r���[���I���`�F�b�N�L�� true:�L false:��
   * @return viewId
   *****************************************************************************
   */
  private String chkViewName(boolean isChecked)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    String retViewId = "";

    // �ėp�����e�[�u�� �r���[���擾�pVO
    XxcsoInstallBasePvDesignVOImpl pvDesignVo = getInstallBasePvDesignVO();
    if ( pvDesignVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallBasePvDesignVOImpl");
    }

    XxcsoInstallBasePvDesignVORowImpl pvDesignVoRow
      = (XxcsoInstallBasePvDesignVORowImpl) pvDesignVo.first();
    if (pvDesignVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBasePvDesignVORowImpl"
        );
    }

    // �I�����ꂽ�r���[ID���擾
      Number selectView = pvDesignVoRow.getSelectView();

    if ( isChecked )
    {
      if ( selectView == null )
      {
        // �r���[���I���G���[
        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00133
           ,XxcsoConstants.TOKEN_ENTRY
           ,XxcsoPvCommonConstants.MSG_VIEW
          );
      }
      retViewId = selectView.toString();
    } else {
      if ( selectView == null )
      {
        retViewId = "";
      } else {
        retViewId = selectView.toString();
      }
    }

    return retViewId;

  }

  /*****************************************************************************
   * ���o�����擾����
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����\���敪
   * @return �\�[�g��SQL���𐬌`����������
   *****************************************************************************
   */
  private String getExtractTerm(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    StringBuffer sbExt = new StringBuffer();

    // �r���[ID���V�[�h�f�[�^�ȊO�̏ꍇ
    if ( !this.isSeedData(viewId) )
    {
      XxcsoInstallBaseExtractTermVOImpl extractTermVo
        = getInstallBaseExtractTermVO();
      if (extractTermVo == null) 
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoInstallBaseExtractTermVOImpl"
          );
      }
      extractTermVo.initQuery(viewId, pvDisplayMode);

      XxcsoInstallBaseExtractTermVORowImpl extractTermVoRow
        = (XxcsoInstallBaseExtractTermVORowImpl) extractTermVo.first();
      if (extractTermVoRow == null)
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoInstallBaseExtractTermVORowImpl"
          );
      }

      int rowCnt = 0;
      while (extractTermVoRow != null)
      {
        // �g�p�\�t���O="1"������
        this.chkEnableFlag(extractTermVoRow.getEnableFlag());

        // �e���v���[�g���擾���A�l�̌���u������
        String termDef    = extractTermVoRow.getExtractTermDef();
        String termType   = extractTermVoRow.getExtractTermType();
        String termMethod = extractTermVoRow.getExtractMethodCode();
        String termValue  = "";
        if(XxcsoPvCommonConstants.EXTRACT_TYPE_VARCHAR2.equals(termType))
        {
          termValue
            = this.getTextString(
                termMethod
               ,extractTermVoRow.getExtractTermText()
              );
        }
        else if (XxcsoPvCommonConstants.EXTRACT_TYPE_NUMBER.equals(termType))
        {
          termValue
            = extractTermVoRow.getExtractTermNumber().toString();
        }
        else if (XxcsoPvCommonConstants.EXTRACT_TYPE_DATE.equals(termType))
        {
          termValue
            = this.getDateString(
                extractTermVoRow.getExtractTermDate().dateValue().toString()
              );
        }

        termDef
          = termDef.replaceAll(XxcsoPvCommonConstants.REPLACE_WORD ,termValue);

        // 1���ږڂɂ��Ă�AND/OR��擪�ɕt�����Ȃ�
        if (rowCnt != 0)
        {
          sbExt.append( XxcsoPvCommonConstants.SPACE );
          sbExt.append( extractTermVoRow.getExtractPattern() );
          sbExt.append( XxcsoPvCommonConstants.SPACE );
        }
        sbExt.append( termDef );

        rowCnt++;
        extractTermVoRow
          = (XxcsoInstallBaseExtractTermVORowImpl) extractTermVo.next();
      }

    }
    // �r���[ID���V�[�h�f�[�^�̏ꍇ
    else
    {
      XxcsoLookupListVOImpl seedExtractTermVo = getSeedExtractTermVO();
      if ( seedExtractTermVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVOImpl");
      }
      seedExtractTermVo.initQuery(
        "XXCSO1_IB_PV_WHERE_000"
        ,null
        ,"1"
      );
      seedExtractTermVo.executeQuery();

      XxcsoLookupListVORowImpl seedExtractTermVoRow
        = (XxcsoLookupListVORowImpl) seedExtractTermVo.first();
      if ( seedExtractTermVoRow == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVORowImpl");
      }

      // �V�[�h�f�[�^�p���o�����e���v���[�g���擾
      String termDef = seedExtractTermVoRow.getDescription();

      // �e���v���[�g�̒u�����������_�R�[�h�ɒu��
      termDef
        = termDef.replaceAll(
            XxcsoPvCommonConstants.REPLACE_WORD
           ,this.getTextString(null, this.getSelfBaseCode())
          );
      sbExt.append(termDef);
    }

    XxcsoUtils.debug(txt, "[END]");

    return new String(sbExt);
  }

  /*****************************************************************************
   * �\�[�g�����擾����
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����\���敪
   * @return �\�[�g��SQL���𐬌`����������
   *****************************************************************************
   */
  private String getSortColumn(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoInstallBaseSortColumnVOImpl sortColumnVo
      = getInstallBaseSortColumnVO();
    if ( sortColumnVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoInstallBaseSortColumnVOImpl"
        );
    }
    sortColumnVo.initQuery(viewId, pvDisplayMode);

    XxcsoInstallBaseSortColumnVORowImpl sortColumnVoRow
      = (XxcsoInstallBaseSortColumnVORowImpl) sortColumnVo.first();
    if ( sortColumnVoRow == null )
    {
      // row�����݂��Ȃ��ꍇ�̓\�[�g�����Ȃ��Ƃ݂Ȃ��I��
      return "";
    }

    StringBuffer sbSort = new StringBuffer();
    while ( sortColumnVoRow != null )
    {
      // �g�p�\�t���O="1"������
      this.chkEnableFlag(sortColumnVoRow.getEnableFlag());

      sbSort.append( sortColumnVoRow.getSortColumn() );
      sbSort.append( XxcsoPvCommonConstants.SPACE );
      sbSort.append( sortColumnVoRow.getSortDirection() );
      sbSort.append( XxcsoPvCommonConstants.COMMA );
      sortColumnVoRow
        = (XxcsoInstallBaseSortColumnVORowImpl) sortColumnVo.next();
    }
    // ������Ō�̃J���}������
    sbSort.deleteCharAt(sbSort.length() - 1);

    XxcsoUtils.debug(txt, "[END]");

    return new String( sbSort );
  }


  /*****************************************************************************
   * �\����擾����
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����\���敪
   * @return �\��������i�[����List->Map
   *****************************************************************************
   */
  private List getViewColumnList(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    List list = new ArrayList();

    // �r���[ID���V�[�h�f�[�^�ȊO�̏ꍇ
    if ( !this.isSeedData(viewId) )
    {
      XxcsoInstallBaseViewColumnVOImpl viewColumnVo
        = getInstallBaseViewColumnVO();
      if (viewColumnVo == null)
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoInstallBaseViewColumnVOImpl"
          );
      }
      viewColumnVo.initQuery(viewId, pvDisplayMode);

      XxcsoInstallBaseViewColumnVORowImpl viewColumnVoRow
        = (XxcsoInstallBaseViewColumnVORowImpl) viewColumnVo.first();

      // VoRow�����݂��Ȃ�=�\���񖢐ݒ�Ƃ݂Ȃ��A�G���[�Ƃ���
      if (viewColumnVoRow == null)
      {
        // �\���񖢐ݒ�G���[
        throw
          XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00494);
      }

      while ( viewColumnVoRow != null )
      {
        HashMap map
          = this.createViewColumnMap(
              viewColumnVoRow.getViewColumnId()
             ,viewColumnVoRow.getViewColumnName()
             ,viewColumnVoRow.getViewColumnId()
             ,viewColumnVoRow.getViewDataType()
            );

        list.add(map);

        viewColumnVoRow
          = (XxcsoInstallBaseViewColumnVORowImpl) viewColumnVo.next();
      }
    }
    // �r���[ID���V�[�h�f�[�^�̏ꍇ
    else
    {
      XxcsoLookupListVOImpl seedViewColumnVo = getSeedViewColumnLookupVO();
      if ( seedViewColumnVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVOImpl");
      }
      StringBuffer sbWhere = new StringBuffer(50);
      sbWhere
        .append("      SUBSTRB(attribute1, ").append(pvDisplayMode)
        .append(", 1) = '1'")
        .append("AND   SUBSTRB(attribute2, ").append(pvDisplayMode)
        .append(", 1) = '1'")
      ;
      seedViewColumnVo.initQuery(
        "XXCSO1_IB_PV_COLUMN_DEF"
        ,new String(sbWhere)
        ,"1"
      );
      seedViewColumnVo.executeQuery();

      XxcsoLookupListVORowImpl seedViewColumnVoRow
        = (XxcsoLookupListVORowImpl) seedViewColumnVo.first();
      if ( seedViewColumnVoRow == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoLookupListVORowImpl");
      }

      while ( seedViewColumnVoRow != null )
      {
        HashMap map
          = this.createViewColumnMap(
              seedViewColumnVoRow.getAttribute7()
             ,seedViewColumnVoRow.getDescription()
             ,seedViewColumnVoRow.getAttribute7()
             ,seedViewColumnVoRow.getAttribute4()
            );
        list.add(map);
        seedViewColumnVoRow
          = (XxcsoLookupListVORowImpl) seedViewColumnVo.next();
      }
    }

    XxcsoUtils.debug(txt, "[END]");

    return list;
  }

  /*****************************************************************************
   * �g�p�\�t���O�`�F�b�N����
   * @param enableFlag 
   * @throw OAException �r���[��`�X�V�G���[
   *****************************************************************************
   */
  private void chkEnableFlag(String enableFlag)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �g�p�\�t���O="1"������
    if ( ! XxcsoPvCommonConstants.FLAG_ENABLE.equals(enableFlag) )
    {
      // �r���[��`�X�V�G���[
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00520);
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �e�L�X�g������擾����
   * @param methodCode
   * @param termText
   * @return �����p�̕�����
   *****************************************************************************
   */
  private String getTextString(
    String methodCode
   ,String termText
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    StringBuffer sb = new StringBuffer();
    sb.append(XxcsoPvCommonConstants.SINGLE_QUOTE);
    // �܂�
    if ( XxcsoPvCommonConstants.METHOD_CONTAIN.equals(methodCode) )
    {
      sb.append("%").append(termText).append("%");
    }
    // �Ŏn�܂�
    else if ( XxcsoPvCommonConstants.METHOD_START.equals(methodCode) )
    {
      sb.append(termText).append("%");
    }
    // �ŏI���
    else if ( XxcsoPvCommonConstants.METHOD_END.equals(methodCode) )
    {
      sb.append("%").append(termText);
    }
    // ��L�ȊO
    else
    {
      sb.append(termText);
    }
    sb.append(XxcsoPvCommonConstants.SINGLE_QUOTE);

    XxcsoUtils.debug(txt, "[END]");

    return new String(sb);
  }

  /*****************************************************************************
   * ���t������擾����
   * @param termDate
   * @return �����p�̕�����
   *****************************************************************************
   */
  private String getDateString(String termDate)
  {
    StringBuffer sbDate = new StringBuffer();
    sbDate.append("TO_DATE(").append(XxcsoPvCommonConstants.SINGLE_QUOTE);
    sbDate.append(termDate);
    sbDate.append(XxcsoPvCommonConstants.SINGLE_QUOTE).append(")");
    return new String(sbDate);
  }

  /*****************************************************************************
   * �V�[�h�f�[�^���菈��
   * @param viewId
   * @return true:�V�[�h�f�[�^�Afalse:�V�[�h�f�[�^�ȊO
   *****************************************************************************
   */
  private boolean isSeedData(String viewId)
  {
    if (XxcsoPvCommonConstants.VIEW_ID_SEED == Integer.parseInt(viewId))
    {
      return true;
    }
    return false;
  }

  /*****************************************************************************
   * �����_�R�[�h�擾����
   * @return  �����_�R�[�h
   * @throw   OAException
   *****************************************************************************
   */
  private String getSelfBaseCode()
  {
    XxcsoPvExtractDispInitVOImpl extDispInitVo = getPvExtractDispInitVO();
    if ( extDispInitVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractDispInitVOImpl");
    }
    extDispInitVo.executeQuery();

    XxcsoPvExtractDispInitVORowImpl extDispInitVoRow
      = (XxcsoPvExtractDispInitVORowImpl) extDispInitVo.first();
    if ( extDispInitVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractDispInitVORowImpl");
    }
    return extDispInitVoRow.getBaseCode();
    
  }

  /*****************************************************************************
   * �������ėp�����\���pmap�쐬
   * @param id       Table���[�W���� ����ID
   * @param name     Table���[�W���� ���ږ�
   * @param attr     Table���[�W���� ViewAttribute
   * @param dataTyep Table���[�W���� ���ڌ^
   * @return URL�Ɉ����n���p�����[�^(HashMap)
   *****************************************************************************
   */
  private HashMap createViewColumnMap(
    String id
   ,String name
   ,String attrName
   ,String dataType
  )
  {
    HashMap map = new HashMap(4);
    map.put(XxcsoPvCommonConstants.KEY_ID,        id);
    map.put(XxcsoPvCommonConstants.KEY_NAME,      name);
    map.put(XxcsoPvCommonConstants.KEY_ATTR_NAME, attrName);
    map.put(XxcsoPvCommonConstants.KEY_DATA_TYPE, dataType);
    return map;
  }
   

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.server", "XxcsoInstallBasePvSearchAMLocal");
  }

  /**
   * 
   * Container's getter for InstallBasePvDesignVO
   */
  public XxcsoInstallBasePvDesignVOImpl getInstallBasePvDesignVO()
  {
    return (XxcsoInstallBasePvDesignVOImpl)findViewObject("InstallBasePvDesignVO");
  }

  /**
   * 
   * Container's getter for InstallBaseExtractTermVO
   */
  public XxcsoInstallBaseExtractTermVOImpl getInstallBaseExtractTermVO()
  {
    return (XxcsoInstallBaseExtractTermVOImpl)findViewObject("InstallBaseExtractTermVO");
  }

  /**
   * 
   * Container's getter for InstallBaseSortColumnVO
   */
  public XxcsoInstallBaseSortColumnVOImpl getInstallBaseSortColumnVO()
  {
    return (XxcsoInstallBaseSortColumnVOImpl)findViewObject("InstallBaseSortColumnVO");
  }

  /**
   * 
   * Container's getter for InstallBaseViewColumnVO
   */
  public XxcsoInstallBaseViewColumnVOImpl getInstallBaseViewColumnVO()
  {
    return (XxcsoInstallBaseViewColumnVOImpl)findViewObject("InstallBaseViewColumnVO");
  }

  /**
   * 
   * Container's getter for SeedViewColumnLookupVO
   */
  public XxcsoLookupListVOImpl getSeedViewColumnLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("SeedViewColumnLookupVO");
  }

  /**
   * 
   * Container's getter for InstallBasePvSumVO
   */
  public XxcsoInstallBasePvSumVOImpl getInstallBasePvSumVO()
  {
    return (XxcsoInstallBasePvSumVOImpl)findViewObject("InstallBasePvSumVO");
  }

  /**
   * 
   * Container's getter for InstallBaseViewSizeVO
   */
  public XxcsoInstallBaseViewSizeVOImpl getInstallBaseViewSizeVO()
  {
    return (XxcsoInstallBaseViewSizeVOImpl)findViewObject("InstallBaseViewSizeVO");
  }

  /**
   * 
   * Container's getter for InstallBasePvChoiceVO
   */
  public XxcsoInstallBasePvChoiceVOImpl getInstallBasePvChoiceVO()
  {
    return (XxcsoInstallBasePvChoiceVOImpl)findViewObject("InstallBasePvChoiceVO");
  }

  /**
   * 
   * Container's getter for SeedExtractTermVO
   */
  public XxcsoLookupListVOImpl getSeedExtractTermVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("SeedExtractTermVO");
  }

  /**
   * 
   * Container's getter for PvExtractDispInitVO
   */
  public XxcsoPvExtractDispInitVOImpl getPvExtractDispInitVO()
  {
    return (XxcsoPvExtractDispInitVOImpl)findViewObject("PvExtractDispInitVO");
  }





}