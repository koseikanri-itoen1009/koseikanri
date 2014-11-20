/*============================================================================
* �t�@�C���� : XxcsoPvRegistAMImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-07 1.0  SCS�������l  �V�K�쐬
* 2009-04-24 1.1  SCS�������l  [ST��QT1_634]��ƈ˗����t���O�ǉ��Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

import java.util.ArrayList;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewLinkImpl;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoConsciousLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso012001j.poplist.server.XxcsoVendorTypeListVOImpl;

/*******************************************************************************
 * �p�[�\�i���C�Y�r���[�쐬��ʂ̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvRegistAMImpl()
  {
  }

  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * ����������(�V�K�쐬)
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����g�p���[�h
   *****************************************************************************
   */
  public void initCreateDetails(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �g�����U�N�V����������
    this.rollback();

    // poplist�̏��������s
    this.initPopList(pvDisplayMode);

    // ��ʂƕR�t���S�Ă�VO�C���X�^���X�̎擾
    XxcsoPvDefFullVOImpl         pvDefVo       = getXxcsoPvDefFullVO1();
    XxcsoEnableColumnSumVOImpl   enableClmSumVo = getXxcsoEnableColumnSumVO1();
    XxcsoDisplayColumnSumVOImpl  dispClmSumVo  = getXxcsoDisplayColumnSumVO1();
    XxcsoPvViewColumnFullVOImpl  viewClmFullVo = getXxcsoPvViewColumnFullVO1();
    XxcsoPvSortColumnFullVOImpl  sortClmFullVo = getXxcsoPvSortColumnFullVO1();
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    this.initAllInstance(
      pvDefVo
     ,enableClmSumVo
     ,dispClmSumVo
     ,viewClmFullVo
     ,sortClmFullVo
     ,extTermFullVo
     ,viewId
     ,pvDisplayMode
     ,true
    );

    // �v���t�@�C���̎擾
    String defaultViewLine
      = txt.getProfile(XxcsoPvCommonConstants.XXCSO1_IB_PV_D_VIEW_LINES);
    if ( defaultViewLine == null || "".equals(defaultViewLine.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoPvCommonConstants.XXCSO1_IB_PV_D_VIEW_LINES
        );
    }

    // ******************************
    // ��ʐݒ�pVO�ւ̒l�̐ݒ�
    // ******************************
    // ��ʃv���p�e�B
    XxcsoPvDefFullVORowImpl pvDefVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefVo.createRow();
    // ��������AND/OR�����w��̏����l��ݒ�
    pvDefVoRow.setExtractPatternCode(XxcsoPvCommonConstants.EXTRACT_AND);
    pvDefVoRow.setViewSize(defaultViewLine);
    pvDefVo.insertRow(pvDefVoRow);

    // �\����(�V�K�쐬)�C���X�^���X
    XxcsoDispayColumnInitVOImpl dispClmInitVo  = getXxcsoDispayColumnInitVO1();
    if ( dispClmInitVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoDispayColumnInitVOImpl");
    }
    dispClmInitVo.initQuery(pvDisplayMode);

    // �\����(�V�K�쐬)�s�C���X�^���X
    XxcsoDispayColumnInitVORowImpl dispClmInitVoRow
      = (XxcsoDispayColumnInitVORowImpl) dispClmInitVo.first();
    if ( dispClmInitVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDispayColumnInitVORowImpl");
    }

    // �\����(�V�K�쐬)�Ŏ擾��������ʗpVO�֐ݒ�
    while (dispClmInitVoRow != null)
    {
      XxcsoDisplayColumnSumVORowImpl dispClmSumVoRow
        = (XxcsoDisplayColumnSumVORowImpl) dispClmSumVo.createRow();

      dispClmSumVoRow.setDescription( dispClmInitVoRow.getDescription() );
      dispClmSumVoRow.setLookupCode( dispClmInitVoRow.getLookupCode() );

      dispClmSumVo.last();
      dispClmSumVo.next();
      dispClmSumVo.insertRow(dispClmSumVoRow);

      dispClmInitVoRow = (XxcsoDispayColumnInitVORowImpl) dispClmInitVo.next();

    }

    // �\�[�g�ݒ� �\���p��Ԑݒ菈��
    this.createSortColumn(sortClmFullVo);

    // ��������(�V�K�쐬)�C���X�^���X
    XxcsoPvExtractTermSumVOImpl extTermSumVo = getXxcsoPvExtractTermSumVO1();
    if ( extTermSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermSumVOImpl");
    }
    extTermSumVo.initQuery(pvDisplayMode);

    // ��������(�V�K�쐬)�s�C���X�^���X
    XxcsoPvExtractTermSumVORowImpl extTermSumVoRow
      = (XxcsoPvExtractTermSumVORowImpl) extTermSumVo.first();
    if ( extTermSumVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermSumVORowImpl");
    }

    // ��������(�V�K�쐬)VO�Ŏ擾��������ʗpVO�֐ݒ�
    while (extTermSumVoRow != null)
    {
      XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.createRow();

      // �s�̕\�������ݒ���s��
      this.setAttributeExtract(
        extTermFullVoRow
       ,extTermSumVoRow.getLookupCode()
       ,null
       ,null
       ,null
       ,null
      );
       
      extTermFullVo.last();
      extTermFullVo.next();
      extTermFullVo.insertRow(extTermFullVoRow);

      extTermSumVoRow = (XxcsoPvExtractTermSumVORowImpl) extTermSumVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * ����������(����)
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����g�p���[�h
   *****************************************************************************
   */
  public Boolean initCopyDetails(
     String viewId
    ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �g�����U�N�V����������
    this.rollback();

    // poplist�̏��������s
    this.initPopList(pvDisplayMode);

    // ��ʂƕR�t���S�Ă�VO�C���X�^���X�̎擾
    XxcsoPvDefFullVOImpl         pvDefVo       = getXxcsoPvDefFullVO1();
    XxcsoEnableColumnSumVOImpl   enableClmSumVo = getXxcsoEnableColumnSumVO1();
    XxcsoDisplayColumnSumVOImpl  dispClmSumVo  = getXxcsoDisplayColumnSumVO1();
    XxcsoPvViewColumnFullVOImpl  viewClmFullVo = getXxcsoPvViewColumnFullVO1();
    XxcsoPvSortColumnFullVOImpl  sortClmFullVo = getXxcsoPvSortColumnFullVO1();
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    this.initAllInstance(
      pvDefVo
     ,enableClmSumVo
     ,dispClmSumVo
     ,viewClmFullVo
     ,sortClmFullVo
     ,extTermFullVo
     ,viewId
     ,pvDisplayMode
     ,true
    );

    // ******************************
    // ��ʐݒ�pVO�ւ̒l�̐ݒ�
    // ******************************
    // �����p�C���X�^���X�̎擾
    // ��ʃv���p�e�B
    XxcsoPvDefFullVOImpl pvDefCopyVo = getXxcsoPvDefCopyVO();
    if ( pvDefCopyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefCopyVO");
    }

    // �\����
    XxcsoPvViewColumnFullVOImpl viewClmCopyVo = getXxcsoPvViewColumnCopyVO();
    if ( viewClmCopyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    // �\�[�g�ݒ�
    XxcsoPvSortColumnFullVOImpl sortClmCopyVo = getXxcsoPvSortColumnCopyVO();
    if ( sortClmCopyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnCopyVO");
    }
    sortClmCopyVo.initQuery(pvDisplayMode);

    // ��������
    XxcsoPvExtractTermFullVOImpl extTermCopyVo = getXxcsoPvExtractTermCopyVO();
    if ( extTermCopyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermCopyVO");
    }
    extTermCopyVo.initQuery(pvDisplayMode);

    // �\�[�g�A����������initQuery������A��ʃv���p�e�B��initQuery���{
    pvDefCopyVo.initQuery(viewId, false);
    XxcsoPvDefFullVORowImpl pvDefCopyVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefCopyVo.first();
    if (pvDefCopyVoRow == null)
    {
      return Boolean.FALSE;
    }
    // �\�[�g����
    // ���ݒ��Ԃ����肤�邽��row��null�`�F�b�N�͍s��Ȃ�
    XxcsoPvSortColumnFullVORowImpl sortClmCopyVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortClmCopyVo.first();

    // ��������
    XxcsoPvExtractTermFullVORowImpl extTermCopyVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermCopyVo.first();
    if (extTermCopyVoRow == null)
    {
      return Boolean.FALSE;
    }


    // ****************************
    // ��������ʐݒ�pVO�֒l�̐ݒ�
    // ****************************

    // ��ʃv���p�e�B
    XxcsoPvDefFullVORowImpl pvDefVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefVo.createRow();

    pvDefVoRow.setViewName(
      pvDefCopyVoRow.getViewName() + XxcsoPvCommonConstants.ADD_VIEW_NAME_COPY
    );
    pvDefVoRow.setViewSize(           pvDefCopyVoRow.getViewSize() );
    pvDefVoRow.setDefaultFlag(        pvDefCopyVoRow.getDefaultFlag() );
    pvDefVoRow.setViewOpenCode(       pvDefCopyVoRow.getViewOpenCode() );
    pvDefVoRow.setDescription(        pvDefCopyVoRow.getDescription() );
    pvDefVoRow.setExtractPatternCode( pvDefCopyVoRow.getExtractPatternCode() );
    pvDefVo.insertRow(pvDefVoRow);

    // �\�[�g�ݒ�
    while( sortClmCopyVoRow != null )
    {
      XxcsoPvSortColumnFullVORowImpl sortClmFullVoRow
        = (XxcsoPvSortColumnFullVORowImpl) sortClmFullVo.createRow();
      sortClmFullVoRow.setColumnCode(sortClmCopyVoRow.getColumnCode());
      sortClmFullVoRow.setSortDirectionCode(
				sortClmCopyVoRow.getSortDirectionCode()
      );

      sortClmFullVo.last();
      sortClmFullVo.next();
      sortClmFullVo.insertRow(sortClmFullVoRow);
      sortClmCopyVoRow = (XxcsoPvSortColumnFullVORowImpl) sortClmCopyVo.next();
    }

    // �\�[�g�ݒ� �\���p��Ԑݒ菈��
    this.createSortColumn(sortClmFullVo);

    // ��������
    while(extTermCopyVoRow != null) 
    {
      XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.createRow();

      // �s�̕\�������ݒ���s��
      this.setAttributeExtract(
        extTermFullVoRow
       ,extTermCopyVoRow.getColumnCode()
       ,extTermCopyVoRow.getExtractMethodCode()
       ,extTermCopyVoRow.getExtractTermText()
       ,extTermCopyVoRow.getExtractTermNumber()
       ,extTermCopyVoRow.getExtractTermDate()
      );

      extTermFullVo.last();
      extTermFullVo.next();
      extTermFullVo.insertRow(extTermFullVoRow);

      extTermCopyVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermCopyVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");

    return Boolean.TRUE;

  }

  /*****************************************************************************
   * ����������(�X�V)
   * @param viewId        �r���[ID
   * @param pvDisplayMode �ėp�����g�p���[�h
   *****************************************************************************
   */
  public Boolean initUpdateDetails(
     String viewId
    ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �g�����U�N�V����������
    this.rollback();

    // poplist�̏��������s
    this.initPopList(pvDisplayMode);

    // ��ʂƕR�t���S�Ă�VO�C���X�^���X�̎擾
    XxcsoPvDefFullVOImpl         pvDefVo       = getXxcsoPvDefFullVO1();
    XxcsoEnableColumnSumVOImpl   enableClmSumVo = getXxcsoEnableColumnSumVO1();
    XxcsoDisplayColumnSumVOImpl  dispClmSumVo  = getXxcsoDisplayColumnSumVO1();
    XxcsoPvViewColumnFullVOImpl  viewClmFullVo = getXxcsoPvViewColumnFullVO1();
    XxcsoPvSortColumnFullVOImpl  sortClmFullVo = getXxcsoPvSortColumnFullVO1();
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    this.initAllInstance(
      pvDefVo
     ,enableClmSumVo
     ,dispClmSumVo
     ,viewClmFullVo
     ,sortClmFullVo
     ,extTermFullVo
     ,viewId
     ,pvDisplayMode
     ,false
    );

    if ( pvDefVo.first() == null)
    {
      return Boolean.FALSE;
    }

    // �\�[�g�ݒ� �\���p��Ԑݒ菈��
    this.createSortColumn(sortClmFullVo);

    // ���������s�C���X�^���X�擾
    XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.first();
    if ( extTermFullVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVORowImpl");
    }
  
    // �擾���J��Ԃ�
    while (extTermFullVoRow != null)
    {
      // �s�̕\�������ݒ���s��
      this.setAttributeExtract(
        extTermFullVoRow
       ,extTermFullVoRow.getColumnCode()
       ,extTermFullVoRow.getExtractMethodCode()
       ,extTermFullVoRow.getExtractTermText()
       ,extTermFullVoRow.getExtractTermNumber()
       ,extTermFullVoRow.getExtractTermDate()
      );

      extTermFullVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");

    return Boolean.TRUE;
  }

  /*****************************************************************************
   * ����{�^������������
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �K�p����ь������s�{�^������������
   * @param list shuttle���[�W����trailing��value�l
   * @return viewId
   *****************************************************************************
   */
  public String handleAppliAndSearchButton(ArrayList list)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �o�^���e���ݒ菈��
    String viewId = this.setPvDefItemFull( list );

    XxcsoUtils.debug(txt, "[END]");

    return viewId;
  }

  /*****************************************************************************
   * �E�v�{�^������������
   * @param list shuttle���[�W����trailing��value�l
   *****************************************************************************
   */
  public void handleApplicationButton(ArrayList list)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �o�^���e���ݒ菈��(�߂�l����)
    this.setPvDefItemFull( list );

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �ǉ��{�^������������
   *****************************************************************************
   */
  public void handleAddtionButton()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // �v���t�@�C���I�v�V�����擾
    String maxFetchSize = txt.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxFetchSize == null || "".equals(maxFetchSize.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    // ��ʃv���p�e�B�C���X�^���X
    XxcsoPvDefFullVOImpl pvDefFullVo = getXxcsoPvDefFullVO1();
    if ( pvDefFullVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // ��ʃv���p�e�B�s�C���X�^���X
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");
    }

    // ���������C���X�^���X�擾
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    if ( extTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }

    // ���������ݒ�ݒ����`�F�b�N
    if (Integer.parseInt(maxFetchSize) <= extTermFullVo.getRowCount())
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00010
          ,XxcsoConstants.TOKEN_OBJECT
          ,XxcsoPvCommonConstants.MSG_EXTRACT_COLUMN
          ,XxcsoConstants.TOKEN_MAX_SIZE
          ,maxFetchSize
        );
    }

    // ���������s�C���X�^���X�쐬
    XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.createRow();

    // �s�̕\�������ݒ���s��
    this.setAttributeExtract(
      extTermFullVoRow
      ,pvDefFullVoRow.getAddColumn()
      ,null
      ,null
      ,null
      ,null
    );
    extTermFullVo.last();
    extTermFullVo.next();
    extTermFullVo.insertRow(extTermFullVoRow);

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * �폜�{�^������������
   *****************************************************************************
   */
  public void handleDeleteButton()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // ���������C���X�^���X�擾
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    if ( extTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    // ���������s�C���X�^���X�쐬
    XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.first();
    // row�����݂��Ȃ��ꍇ�ɍ폜�{�^������������邱�Ƃ͂��肦�Ȃ�
    if ( extTermFullVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVORowImpl");
    }

    boolean isDelete = false;

    while ( extTermFullVoRow != null)
    {
      if ("Y".equals( extTermFullVoRow.getSelectFlag() ) )
      {
        extTermFullVo.removeCurrentRow();
        isDelete = true;
      }
      extTermFullVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.next();
    }

    if ( !isDelete )
    {
      // �����������I���G���[
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00133
         ,XxcsoConstants.TOKEN_ENTRY
         ,XxcsoPvCommonConstants.MSG_RECORD
        );
    }
    XxcsoUtils.debug(txt, "[END]");

  }

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
   * ��ʓo�^�p�C���X�^���X����������
   * @param pvDefVo        ��ʃv���p�e�B�C���X�^���X
   * @param enableClmSumVo �g�p�\��C���X�^���X
   * @param dispClmSumVo   �\����(�\���p)�C���X�^���X
   * @param viewClmFullVo  �\����(�o�^�p)�C���X�^���X
   * @param sortClmFullVo  �\�[�g��C���X�^���X
   * @param extTermFullVo  ����������C���X�^���X
   * @param viewId         �r���[ID
   * @param pvDisplayMode  �ėp�����g�p���[�h
   * @param isCopy         true:�V�K�쐬�A���� false:�X�V
   *****************************************************************************
   */
  private void initAllInstance(
    XxcsoPvDefFullVOImpl         pvDefVo
   ,XxcsoEnableColumnSumVOImpl   enableClmSumVo
   ,XxcsoDisplayColumnSumVOImpl  dispClmSumVo
   ,XxcsoPvViewColumnFullVOImpl  viewClmFullVo
   ,XxcsoPvSortColumnFullVOImpl  sortClmFullVo
   ,XxcsoPvExtractTermFullVOImpl extTermFullVo
   ,String viewId
   ,String pvDisplayMode
   ,boolean isCopy
  )
  {

    // ��ʃv���p�e�B�̃C���X�^���X�擾
    if (pvDefVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    pvDefVo.initQuery(viewId, isCopy);

    // �g�p�\��C���X�^���X�擾
    if ( enableClmSumVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEnableColumnSumVOImpl");
    }
    enableClmSumVo.initQuery(viewId, pvDisplayMode);
    enableClmSumVo.first();

    // �\����C���X�^���X�擾�i�\���p�j
    if ( dispClmSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDisplayColumnSumVOImpl");
    }
    dispClmSumVo.initQuery(viewId, pvDisplayMode);
    dispClmSumVo.first();

    // �\����C���X�^���X�擾�i�o�^�p�j
    // ���o�^�O�ɂ����ŏ�����
    if ( viewClmFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    // �\�[�g�ݒ�C���X�^���X�擾
    if ( sortClmFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnFullVOImpl");
    }
    sortClmFullVo.initQuery(pvDisplayMode);

    // ���������C���X�^���X�擾
    if ( extTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    extTermFullVo.initQuery(pvDisplayMode);

  }

  /*****************************************************************************
   * �R�~�b�g����
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * ���[���o�b�N����
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * poplist����������
   * @param pvDisplayMode �ėp�����g�p���[�h
   *****************************************************************************
   */
  private void initPopList(
    String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // ****************************************
    // *****Lookup�̏�����*********************
    // ****************************************
    // *****��ʎw�胊�[�W����
    // �\���s��
    XxcsoLookupListVOImpl viewSizeLookupVo = getXxcsoViewSizeLookupListVO();
    if ( viewSizeLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoViewSizeLookupListVO");
    }
    viewSizeLookupVo.initQuery("XXCSO1_IB_PV_VIEW_LINES", null, "1");
    viewSizeLookupVo.executeQuery();

    // *****�\�[�g�ݒ胊�[�W����
    // ��
    XxcsoLookupListVOImpl columnNameLookupVo = getXxcsoColumnNameLookupVO();
    if ( columnNameLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoColumnNameLookupVO");
    }
    StringBuffer sbWhere1 = new StringBuffer(50);
    sbWhere1
      .append("      SUBSTRB(attribute1, ").append(pvDisplayMode)
      .append(", 1) = '1'")
    ;
    columnNameLookupVo.initQuery(
      "XXCSO1_IB_PV_COLUMN_DEF"
      ,new String(sbWhere1)
      ,"TO_NUMBER(lookup_code)"
    );
    columnNameLookupVo.executeQuery();

    // �\�[�g��
    XxcsoLookupListVOImpl sortDirectionLookupVo
      = getXxcsoSortDirectionLookupVO();
    if ( sortDirectionLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSortDirectionLookupVO");
    }
    sortDirectionLookupVo.initQuery(
      "XXCSO1_IB_PV_SORT_TYPE"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    sortDirectionLookupVo.executeQuery();


    // *****�����������[�W����
    // �����ǉ�
    XxcsoLookupListVOImpl addConditionLookupVo = getXxcsoAddConditionLookupVO();
    if ( addConditionLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAddConditionLookupVO");
    }
    StringBuffer sbWhere2 = new StringBuffer(100);
    sbWhere2
      .append("      SUBSTRB(attribute1, ").append(pvDisplayMode)
      .append(", 1) = '1'")
      .append("AND   SUBSTRB(attribute3, ").append(pvDisplayMode)
      .append(", 1) = '1'")
    ;

    addConditionLookupVo.initQuery(
      "XXCSO1_IB_PV_COLUMN_DEF"
      ,new String(sbWhere2)
      ,"TO_NUMBER(lookup_code)"
    );
    addConditionLookupVo.executeQuery();

    // ���o���@(�e�L�X�g(����))
    XxcsoLookupListVOImpl modeTextLookupVo = getXxcsoModeTextLookupVO();
    if ( modeTextLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeTextLookupVO");
    }
    modeTextLookupVo.initQuery(
      "XXCSO1_IB_PV_VARCHAR2"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeTextLookupVo.executeQuery();

    // ���o���@(�e�L�X�g(����))
    XxcsoLookupListVOImpl modeNumberLookupVo = getXxcsoModeNumberLookupVO();
    if ( modeNumberLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeDateLookupVO");
    }
    modeNumberLookupVo.initQuery(
      "XXCSO1_IB_PV_NUMBER"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeNumberLookupVo.executeQuery();

    // ���o���@(���t)
    XxcsoLookupListVOImpl modeDateLookupVo = getXxcsoModeDateLookupVO();
    if ( modeDateLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeDateLookupVO");
    }
    modeDateLookupVo.initQuery(
      "XXCSO1_IB_PV_DATE"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeDateLookupVo.executeQuery();

    // ���o���@(LOV)
    XxcsoLookupListVOImpl modeLovLookupVo = getXxcsoModeLovLookupVO();
    if ( modeLovLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeLovLookupVO");
    }
    modeLovLookupVo.initQuery(
      "XXCSO1_IB_PV_MATCH"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeLovLookupVo.executeQuery();

    // ���o���@(�|�b�v���X�g)
    XxcsoLookupListVOImpl modePoplistLookupVo = getXxcsoModePoplistLookupVO();
    if ( modePoplistLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModePoplistLookupVO");
    }
    modePoplistLookupVo.initQuery(
      "XXCSO1_IB_PV_MATCH"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modePoplistLookupVo.executeQuery();

    // AND/OR�����w��
    XxcsoLookupListVOImpl andOrLookupVo = getXxcsoAndOrLookupVO();
    if (andOrLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAndOrLookupVO");
    }
    andOrLookupVo.initQuery(
      "XXCSO1_IB_PV_AND_OR"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    andOrLookupVo.executeQuery();

    // �@��敪 where020
    XxcsoVendorTypeListVOImpl vendorTypeListVo = getXxcsoVendorTypeListVO1();
    if (vendorTypeListVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoVendorTypeListVO1");
    }

    // �@����1 where060
    XxcsoLookupListVOImpl where060LookupVo = getXxcsoWhere060LookupVO();
    if (where060LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere060LookupVO");
    }
    where060LookupVo.initQuery(
      "XXCSO1_CSI_JOTAI_KBN1"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where060LookupVo.executeQuery();

    // �@����2 where070
    XxcsoLookupListVOImpl where070LookupVo = getXxcsoWhere070LookupVO();
    if (where070LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere070LookupVO");
    }
    where070LookupVo.initQuery(
      "XXCSO1_CSI_JOTAI_KBN2"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where070LookupVo.executeQuery();

    // �@����3 where080
    XxcsoLookupListVOImpl where080LookupVo = getXxcsoWhere080LookupVO();
    if (where080LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere080LookupVO");
    }
    where080LookupVo.initQuery(
      "XXCSO1_CSI_JOTAI_KBN3"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where080LookupVo.executeQuery();

    // ���[�J�[�R�[�h  where150
    XxcsoLookupListVOImpl where150LookupVo = getXxcsoWhere150LookupVO();
    if (where150LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere150LookupVO");
    }
    where150LookupVo.initQuery(
      "XXCSO_CSI_MAKER_CODE"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where150LookupVo.executeQuery();

    // �ݒu�Ǝ�敪  where220
    XxcsoConsciousLookupListVOImpl where220LookupVo
      = getXxcsoWhere220LookupVO();
    if (where220LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere220LookupVO");
    }
    where220LookupVo.initQuery(
      "XXCMM"
     ,"AU"
     ,"XXCMM_CUST_GYOTAI_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where220LookupVo.executeQuery();

    // ����@1 where300
    XxcsoLookupListVOImpl where300LookupVo = getXxcsoWhere300LookupVO();
    if (where300LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere300LookupVO");
    }
    where300LookupVo.initQuery(
      "XXCSO_CSI_TOKUSHUKI"
     ,null
     ,"TO_NUMBER(lookup_code)"
     );
    where300LookupVo.executeQuery();

    // ����@2 where310
    XxcsoLookupListVOImpl where310LookupVo = getXxcsoWhere310LookupVO();
    if (where310LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere310LookupVO");
    }
    where310LookupVo.initQuery(
      "XXCSO_CSI_TOKUSHUKI"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where310LookupVo.executeQuery();

    // ����@3 where320
    XxcsoLookupListVOImpl where320LookupVo = getXxcsoWhere320LookupVO();
    if (where320LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere320LookupVO");
    }
    where320LookupVo.initQuery(
      "XXCSO_CSI_TOKUSHUKI"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where320LookupVo.executeQuery();

    // ���[�X���(�ă��[�X)  where510
    XxcsoLookupListVOImpl where510LookupVo = getXxcsoWhere510LookupVO();
    if (where510LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere510LookupVO");
    }
    where510LookupVo.initQuery(
      "XXCFF1_OBJECT_STATUS"
     ,"attribute1 = '1'"
     ,"TO_NUMBER(lookup_code)"
    );
    where510LookupVo.executeQuery();

    // �ݒu�ꏊ where550
    XxcsoConsciousLookupListVOImpl where550LookupVo
      = getXxcsoWhere550LookupVO();
    if (where550LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere550LookupVO");
    }
    where550LookupVo.initQuery(
      "XXCMM"
     ,"AU"
     ,"XXCMM_CUST_VD_SECCHI_BASYO"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where550LookupVo.executeQuery();

    // �Ƒ�(������) where560
    XxcsoConsciousLookupListVOImpl where560LookupVo
      = getXxcsoWhere560LookupVO();
    if (where560LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere560LookupVO");
    }
    where560LookupVo.initQuery(
      "XXCMM"
     ,"AU"
     ,"XXCMM_CUST_GYOTAI_SHO"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where560LookupVo.executeQuery();

    // �ŏI�ݒu�敪 where600
    XxcsoLookupListVOImpl where600LookupVo = getXxcsoWhere600LookupVO();
    if (where600LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere600LookupVO");
    }
    where600LookupVo.initQuery(
      "XXCSO1_CSI_JOB_KBN2"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where600LookupVo.executeQuery();

    // �ŏI�ݒu�i�� where610
    XxcsoLookupListVOImpl where610LookupVo = getXxcsoWhere610LookupVO();
    if (where610LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere610LookupVO");
    }
    where610LookupVo.initQuery(
      "XXCSO1_CSI_SINTYOKU_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where610LookupVo.executeQuery();

    // �ŏI�ݔ����e where620
    XxcsoLookupListVOImpl where620LookupVo = getXxcsoWhere620LookupVO();
    if (where620LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere620LookupVO");
    }
    where620LookupVo.initQuery(
      "XXCSO1_SAGYO_LEVEL"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where620LookupVo.executeQuery();

    // �ŏI��Ƌ敪 where660
    XxcsoLookupListVOImpl where660LookupVo = getXxcsoWhere660LookupVO();
    if (where660LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere660LookupVO");
    }
    where660LookupVo.initQuery(
      "XXCSO1_CSI_JOB_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where660LookupVo.executeQuery();

    // �ŏI��Ɛi�� where670
    XxcsoLookupListVOImpl where670LookupVo = getXxcsoWhere670LookupVO();
    if (where670LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere670LookupVO");
    }
    where670LookupVo.initQuery(
      "XXCSO1_CSI_SINTYOKU_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where670LookupVo.executeQuery();

    // �]���p���� where730
    XxcsoLookupListVOImpl where730LookupVo = getXxcsoWhere730LookupVO();
    if (where730LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere730LookupVO");
    }
    where730LookupVo.initQuery(
      "XXCSO1_CSI_TENHAI_FLG"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where730LookupVo.executeQuery();

    // �]�������敪 where740
    XxcsoLookupListVOImpl where740LookupVo = getXxcsoWhere740LookupVO();
    if (where740LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere740LookupVO");
    }
    where740LookupVo.initQuery(
      "XXCSO1_CSI_KANRYO_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where740LookupVo.executeQuery();

    // ���[�J�[�� where770
    XxcsoLookupListVOImpl where770LookupVo = getXxcsoWhere770LookupVO();
    if (where770LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere770LookupVO");
    }
    where770LookupVo.initQuery(
      "XXCSO_CSI_MAKER_CODE"
      ,null
      ,"TO_NUMBER(lookup_code)"
    );
    where150LookupVo.executeQuery();

    // ���S�ݒu� where780
    XxcsoLookupListVOImpl where780LookupVo = getXxcsoWhere780LookupVO();
    if (where780LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere780LookupVO");
    }
    where780LookupVo.initQuery(
      "XXCSO1_CSI_SAFETY_LEVEL"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where780LookupVo.executeQuery();

// 2009/04/24 [ST��QT1_634] Add Start
    XxcsoLookupListVOImpl where790LookupVo = getXxcsoWhere790LookupVO();
    if (where790LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere790LookupVO");
    }
    where790LookupVo.initQuery(
      "XXCSO1_OP_REQUEST_FLAG"
     ,null
     ,"lookup_code"
    );
    where790LookupVo.executeQuery();
// 2009/04/24 [ST��QT1_634] Add End

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * �\�[�g�ݒ� �s�쐬
   * @param XxcsoPvSortColumnFullVOImpl �\�[�g�\���C���X�^���X
   *****************************************************************************
   */
  private void createSortColumn(XxcsoPvSortColumnFullVOImpl sortColumnVo)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // insert����t���O
    boolean isInsert = false;

    XxcsoPvSortColumnFullVORowImpl sortColumnVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.first();
    if ( sortColumnVoRow == null )
    {
      sortColumnVoRow
        = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.createRow();
      isInsert = true;
    }

    // �\�[�g�ݒ�s�C���X�^���X�𐶐����󔒍s��}��
    for (int i = 0; i < XxcsoPvCommonConstants.SORT_SETTING_SIZE; i++)
    {

      if (sortColumnVoRow == null)
      {
        isInsert = true;

        sortColumnVoRow
          = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.createRow();
      }

      // �s���o���̍쐬
      StringBuffer sb = new StringBuffer(10);
      sb.append( XxcsoPvCommonConstants.SORT_LINE_CAPTION1 );
      sb.append( String.valueOf( i + 1 ) );
      sb.append( XxcsoPvCommonConstants.SORT_LINE_CAPTION2 );

      // �l�̐ݒ�
      sortColumnVoRow.setLineCaption(new String(sb));

      if ( isInsert )
      {
        sortColumnVo.last();
        sortColumnVo.next();
        sortColumnVo.insertRow(sortColumnVoRow);
      } 
      sortColumnVoRow = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.next();
    }

    XxcsoUtils.debug(txt, "[End]");
  }

  /*****************************************************************************
   * ���o�����s�����ݒ�
   * @param extractRow  �s�C���X�^���X
   * @param lookupCode  �N�C�b�N�R�[�h
   *****************************************************************************
   */
  private void setAttributeExtract(
    XxcsoPvExtractTermFullVORowImpl extractRow
   ,String                         columnCode
   ,String                         mehodCode
   ,String                         termText
   ,String                         termNumber
   ,Date                           termDate
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    for (int i = 0; i < XxcsoPvCommonConstants.EXTRACT_SIZE; i++)
    {
      // Attribute�ݒ�p������̐���
      String attStr = String.valueOf( ( i + 1 ) * 10 );

      // 2����0���ߑΉ�
      if (attStr.length() == 2)
      {
        attStr = "0" + attStr;
      }
      if ( attStr.equals(columnCode) )
      {
        extractRow.setColumnCode(columnCode);          // ��R�[�h
        extractRow.setExtractMethodCode(mehodCode);    // ���o���@�R�[�h
        if ( !isNull(termText) )
        {
          extractRow.setExtractTermText(termText);     // ���o����(����/LOV)
        }
        if ( !isNull(termNumber) )
        {
          extractRow.setExtractTermNumber(termNumber); // ���o����(����)
        }
        if ( !isNull(termDate) )
        {
          extractRow.setExtractTermDate(termDate);     // ���o����(���t)
        }
        // �����_�����O=true
        extractRow.setAttribute(
          XxcsoPvCommonConstants.EXTRACT_RENDER + attStr
         ,Boolean.TRUE
        );

        // ��R�[�h=���_�R�[�h���̏����l�ݒ�
        if (
          ( XxcsoPvCommonConstants.EXTRACT_VALUE_010.equals(columnCode) ) &&
          ( isNull(termText) )
        )
        {
          extractRow.setExtractTermText(this.getSelfBaseCode());  
        }
      } else {

        // �����_�����O=false
        extractRow.setAttribute(
          XxcsoPvCommonConstants.EXTRACT_RENDER + attStr
         ,Boolean.FALSE
        );
      }
    }
    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * �o�^���e�ݒ菈��
   * @param  trailingList shuttle���[�W����trailing��value�l
   * @return �o�^�^�����^�X�V���̃r���[ID 
   *****************************************************************************
   */
  private String setPvDefItemFull(ArrayList trailingList)
  {

    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    String tokenValue = ""; // �������̕t�����b�Z�[�W(�o�^or�X�V)
    String updViewId = "";  // �X�V�r���[ID 
    String viewName = null; // �r���[��

    // **************
    // �r���[���̎擾
    // **************
    // ��ʃv���p�e�B
    XxcsoPvDefFullVOImpl pvDefVo = getXxcsoPvDefFullVO1();
    if (pvDefVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    XxcsoPvDefFullVORowImpl pvDefVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefVo.first();
    if (pvDefVoRow == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");
    }

    viewName = pvDefVoRow.getViewName();
    // �r���[�����̓`�F�b�N����
    if ( viewName == null || "".equals(viewName.trim()) )
    {
      // �r���[�������̓G���[
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00005
         ,XxcsoConstants.TOKEN_COLUMN
         ,XxcsoPvCommonConstants.MSG_VIEW_NAME
        );
    }


    // �o�^�E�����E�X�V�ł̏�������
    // �X�V�̏ꍇ
    if (pvDefVoRow.getViewId().longValue() > 0) 
    {
      tokenValue = XxcsoConstants.TOKEN_VALUE_UPDATE;
      updViewId = pvDefVoRow.getViewId().toString();
    }
    // �o�^�E�����̏ꍇ
    else
    {
      tokenValue = XxcsoConstants.TOKEN_VALUE_REGIST;

      // �\���L���t���O�̐ݒ�
      pvDefVoRow.setViewOpenCode(XxcsoPvCommonConstants.VIEW_OPEN_CODE_OPEN);

    }

    // �f�t�H���g�t���OON�̏ꍇ
    if (XxcsoPvCommonConstants.DEFAULT_FLAG_YES.equals(
          pvDefVoRow.getDefaultFlag())
       )
    {
      // ���̃f�t�H���g�t���O��OFF�ɐݒ肷��
      this.updDefaultFlg(updViewId);
    }

    // **************************
    // �\���񃊁[�W�����ݒ菇�ݒ�
    // **************************
    int listSize = trailingList.size();
    if (listSize == 0)
    {
      // �\���񖢐ݒ�G���[
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00494);
    }

    // �\����(�o�^�p)�C���X�^���X�擾
    XxcsoPvViewColumnFullVOImpl viewColumnFullVo
      = getXxcsoPvViewColumnFullVO1();
    if ( viewColumnFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    int setupNumberView = 1;

    XxcsoPvViewColumnFullVORowImpl viewColumnFullVoRow
      = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.first();

    boolean isCleate = false;

    // ��ʂ̓��e�ŏ���1����ݒ�
    for (int i = 0; i < listSize; i++)
    {
      isCleate = false;

      if (viewColumnFullVoRow == null)
      {
        viewColumnFullVoRow
          = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.createRow();
        isCleate = true;
      }

      viewColumnFullVoRow.setSetupNumber(new Number(setupNumberView++));
      viewColumnFullVoRow.setColumnCode( (String) trailingList.get(i));

      if ( isCleate )
      {
        viewColumnFullVo.last();
        viewColumnFullVo.next();
        viewColumnFullVo.insertRow(viewColumnFullVoRow);
      }

      viewColumnFullVoRow
        = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.next();
    }

    // �\���񏉊��\�����I�u�W�F�N�g�ɂ܂��f�[�^������ꍇ�͍폜����
    while ( viewColumnFullVoRow != null )
    {
      viewColumnFullVo.removeCurrentRow();
      viewColumnFullVoRow
        = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.next();
    }

    // ******************************
    // ���������񃊁[�W�����ݒ蔻��
    // ******************************
    XxcsoPvExtractTermFullVOImpl extractTermFullVo
      = getXxcsoPvExtractTermFullVO1();
    if ( extractTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    XxcsoPvExtractTermFullVORowImpl extractTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.first();

    boolean isSetting = false; // �ݒ蔻��p�t���O
    while ( extractTermFullVoRow != null )
    {
      String extColumnCode = extractTermFullVoRow.getColumnCode();
      String extMethodCode = extractTermFullVoRow.getExtractMethodCode();
      String extTermText   = extractTermFullVoRow.getExtractTermText();
      // ���_�E�����E�ڋq�̃R�[�h�̂����ꂩ�ɒl���ݒ肳��Ă��邩�`�F�b�N
      if ( XxcsoPvCommonConstants.EXTRACT_VALUE_010.equals(extColumnCode)
        || XxcsoPvCommonConstants.EXTRACT_VALUE_030.equals(extColumnCode)
        || XxcsoPvCommonConstants.EXTRACT_VALUE_090.equals(extColumnCode)
      )
      {
        if ( !isNull(extMethodCode) && !isNull(extTermText) ) 
        {
          // ������ł��ݒ肳��Ă���΃t���O��true�ɐݒ�
          isSetting = true;
        }
      }
      extractTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.next();

    }

    if ( !isSetting )
    {
      // ���������ݒ�s���G���[
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00455);
    }

    // ****************************
    // �\�[�g�񃊁[�W�����ݒ菇�ݒ�
    // ****************************
    XxcsoPvSortColumnFullVOImpl sortColumnFullVo
      = getXxcsoPvSortColumnFullVO1();
    if ( sortColumnFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnFullVOImpl");
    }
    XxcsoPvSortColumnFullVORowImpl sortColumnFullVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortColumnFullVo.first();

    int setupNumberSort = 1;

    // ��ʂ̓��e�ŏ���1����ݒ�
    while ( sortColumnFullVoRow != null )
    {
      String columnCode = sortColumnFullVoRow.getColumnCode();
      String sortDirectionCode = sortColumnFullVoRow.getSortDirectionCode();
      // �\�[�g�񖼂ƃ\�[�g���̂����ꂩ���ݒ肳��Ă��Ȃ��ꍇ
      if ( isNull(columnCode) || isNull(sortDirectionCode) ) 
      {
        // �Ώۍs���폜���A���s��
        sortColumnFullVo.removeCurrentRow();
      }
      else
      {
        sortColumnFullVoRow.setSetupNumber(new Number(setupNumberSort++));
      }

      sortColumnFullVoRow
        = (XxcsoPvSortColumnFullVORowImpl) sortColumnFullVo.next();
    }

    // ******************************
    // ���������񃊁[�W�����ݒ菇�ݒ�
    // ******************************
    extractTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.first();
    
    int setupNumberExt = 1;
    // ��ʂ̓��e�ŏ���1����ݒ�
    while ( extractTermFullVoRow != null )
    {
      String extMethodCode = extractTermFullVoRow.getExtractMethodCode();
      String extTermText   = extractTermFullVoRow.getExtractTermText();
      String extTermNumber = extractTermFullVoRow.getExtractTermNumber();
      Date extTermDate   = extractTermFullVoRow.getExtractTermDate();
      // ���o�񖼂ƒ��o���@�̂����ꂩ���ݒ肳��Ă��Ȃ��ꍇ
      if ( isNull(extMethodCode) || 
         ( isNull(extTermText) && isNull(extTermNumber) &&
           isNull(extTermDate)
         )
      )
      {
        // �Ώۍs���폜
        extractTermFullVo.removeCurrentRow();
      }
      else
      {
        extractTermFullVoRow.setSetupNumber(new Number(setupNumberExt++));
      }

      extractTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.next();

    }

    // �ۑ����������s���܂��B
    this.commit();

    // �����o���ꂽ�r���[ID��ޔ�
    String targetViewId = pvDefVoRow.getViewId().toString();

    // �������b�Z�[�W�̐ݒ�
    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,viewName
         ,XxcsoConstants.TOKEN_ACTION
         ,tokenValue
        );

    XxcsoUtils.debug(txt, "[END]");

    return targetViewId;
  }
  
  /*****************************************************************************
   * �f�t�H���g�t���O�X�V����
   * @param  viewId    �r���[ID
   *****************************************************************************
   */
  private void updDefaultFlg(String viewId)
  {
    // ���݃f�t�H���g�t���O���ݒ肳��Ă���ėp�����e�[�u�����擾
    XxcsoPvDefUpdDfltFlgVOImpl pvDefDefltFlgVo = getXxcsoPvDefUpdDfltFlgVO();
    if ( pvDefDefltFlgVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefUpdDfltFlgImpl");
    }
    pvDefDefltFlgVo.initQuery(viewId);

    XxcsoPvDefUpdDfltFlgVORowImpl pvDefDefltFlgVoRow
      = (XxcsoPvDefUpdDfltFlgVORowImpl) pvDefDefltFlgVo.first();
    if ( pvDefDefltFlgVoRow == null )
    {
      // row�����݂��Ȃ�=0���Ƃ݂Ȃ��A�����I��
      return;
    }

    while (pvDefDefltFlgVoRow != null)
    {
      // "Y"�ɐݒ肳��Ă�����̂͑S��"N"�ɂ���
      pvDefDefltFlgVoRow.setDefaultFlag(XxcsoPvCommonConstants.DEFAULT_FLAG_NO);
      pvDefDefltFlgVoRow
        = (XxcsoPvDefUpdDfltFlgVORowImpl) pvDefDefltFlgVo.next();
    }

    return;
  }
  
  /*****************************************************************************
   * �����_�R�[�h�擾����
   * @return  �����_�R�[�h
   * @throw   OAException
   *****************************************************************************
   */
  private String getSelfBaseCode()
  {
    XxcsoPvExtractDispInitVOImpl extDispInitVo = getXxcsoPvExtractDispInitVO();
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
   * Null�`�F�b�N
   * @param  obj    Null�`�F�b�N���s���I�u�W�F�N�g
   * @return true   Null(String�̏ꍇ��null�܂��͋󕶎�)
   *         false  not Null
   *****************************************************************************
   */
  private boolean isNull(Object obj)
  {
    if (obj instanceof String)
    {
      if (obj == null || "".equals(obj.toString()))
      {
        return true;
      }
    }
    else
    {
      if (obj == null)
      {
        return true;
      }
    }
    return false;
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.server", "xxcsoPersonalizedViewRegistAMLocal");
  }


  /**
   * 
   * Container's getter for XxcsoViewSizeLookupListVO
   */
  public XxcsoLookupListVOImpl getXxcsoViewSizeLookupListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoViewSizeLookupListVO");
  }

  /**
   * 
   * Container's getter for XxcsoAddConditionLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoAddConditionLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoAddConditionLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeTextLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeTextLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeTextLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeDateLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeDateLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeDateLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeLovLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeLovLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeLovLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModePoplistLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModePoplistLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModePoplistLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeNumberLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeNumberLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeNumberLookupVO");
  }



  /**
   * 
   * Container's getter for XxcsoColumnNameLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoColumnNameLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoColumnNameLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoSortDirectionLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoSortDirectionLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoSortDirectionLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefFullVO1
   */
  public XxcsoPvDefFullVOImpl getXxcsoPvDefFullVO1()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("XxcsoPvDefFullVO1");
  }




  /**
   * 
   * Container's getter for XxcsoPvExtractTermSumVO1
   */
  public XxcsoPvExtractTermSumVOImpl getXxcsoPvExtractTermSumVO1()
  {
    return (XxcsoPvExtractTermSumVOImpl)findViewObject("XxcsoPvExtractTermSumVO1");
  }






  /**
   * 
   * Container's getter for XxcsoEnableColumnSumVO1
   */
  public XxcsoEnableColumnSumVOImpl getXxcsoEnableColumnSumVO1()
  {
    return (XxcsoEnableColumnSumVOImpl)findViewObject("XxcsoEnableColumnSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoWhere310LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere310LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere310LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere320LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere320LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere320LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere510LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere510LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere510LookupVO");
  }



  /**
   * 
   * Container's getter for XxcsoWhere600LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere600LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere600LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere610LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere610LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere610LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere660LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere660LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere660LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere670LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere670LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere670LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere730LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere730LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere730LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere740LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere740LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere740LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere770LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere770LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere770LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere780LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere780LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere780LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoAndOrLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoAndOrLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoAndOrLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere060LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere060LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere060LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere070LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere070LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere070LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere150LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere150LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere150LookupVO");
  }


  /**
   * 
   * Container's getter for XxcsoWhere080LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere080LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere080LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere300LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere300LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere300LookupVO");
  }



  /**
   * 
   * Container's getter for XxcsoPvDefFullCopyVO
   */
  public XxcsoPvDefFullVOImpl getXxcsoPvDefFullCopyVO()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("XxcsoPvDefFullCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvViewColumnFullCopyVO
   */
  public XxcsoPvViewColumnFullVOImpl getXxcsoPvViewColumnFullCopyVO()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("XxcsoPvViewColumnFullCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvSortColumnFullCopyVO
   */
  public XxcsoPvSortColumnFullVOImpl getXxcsoPvSortColumnFullCopyVO()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("XxcsoPvSortColumnFullCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractTermFullCopyVO
   */
  public XxcsoPvExtractTermFullVOImpl getXxcsoPvExtractTermFullCopyVO()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("XxcsoPvExtractTermFullCopyVO");
  }




  /**
   * 
   * Container's getter for XxcsoPvDefCopyVO
   */
  public XxcsoPvDefFullVOImpl getXxcsoPvDefCopyVO()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("XxcsoPvDefCopyVO");
  }






  /**
   * 
   * Container's getter for XxcsoDispayColumnInitVO1
   */
  public XxcsoDispayColumnInitVOImpl getXxcsoDispayColumnInitVO1()
  {
    return (XxcsoDispayColumnInitVOImpl)findViewObject("XxcsoDispayColumnInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoDisplayColumnSumVO1
   */
  public XxcsoDisplayColumnSumVOImpl getXxcsoDisplayColumnSumVO1()
  {
    return (XxcsoDisplayColumnSumVOImpl)findViewObject("XxcsoDisplayColumnSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvViewColumnFullVO1
   */
  public XxcsoPvViewColumnFullVOImpl getXxcsoPvViewColumnFullVO1()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("XxcsoPvViewColumnFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractTermFullVO1
   */
  public XxcsoPvExtractTermFullVOImpl getXxcsoPvExtractTermFullVO1()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("XxcsoPvExtractTermFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvSortColumnFullVO1
   */
  public XxcsoPvSortColumnFullVOImpl getXxcsoPvSortColumnFullVO1()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("XxcsoPvSortColumnFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvSortColumnCopyVO
   */
  public XxcsoPvSortColumnFullVOImpl getXxcsoPvSortColumnCopyVO()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("XxcsoPvSortColumnCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractTermCopyVO
   */
  public XxcsoPvExtractTermFullVOImpl getXxcsoPvExtractTermCopyVO()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("XxcsoPvExtractTermCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefViewColumnVL1
   */
  public ViewLinkImpl getXxcsoPvDefViewColumnVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefViewColumnVL1");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefExtractTermVL1
   */
  public ViewLinkImpl getXxcsoPvDefExtractTermVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefExtractTermVL1");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefSortColumnVL1
   */
  public ViewLinkImpl getXxcsoPvDefSortColumnVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefSortColumnVL1");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefSortColumnVL2
   */
  public ViewLinkImpl getXxcsoPvDefSortColumnVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefSortColumnVL2");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefExtractTermVL2
   */
  public ViewLinkImpl getXxcsoPvDefExtractTermVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefExtractTermVL2");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefUpdDfltFlgVO
   */
  public XxcsoPvDefUpdDfltFlgVOImpl getXxcsoPvDefUpdDfltFlgVO()
  {
    return (XxcsoPvDefUpdDfltFlgVOImpl)findViewObject("XxcsoPvDefUpdDfltFlgVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractDispInitVO
   */
  public XxcsoPvExtractDispInitVOImpl getXxcsoPvExtractDispInitVO()
  {
    return (XxcsoPvExtractDispInitVOImpl)findViewObject("XxcsoPvExtractDispInitVO");
  }


  /**
   * 
   * Container's getter for XxcsoWhere620LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere620LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere620LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere220LookupVO
   */
  public XxcsoConsciousLookupListVOImpl getXxcsoWhere220LookupVO()
  {
    return (XxcsoConsciousLookupListVOImpl)findViewObject("XxcsoWhere220LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere550LookupVO
   */
  public XxcsoConsciousLookupListVOImpl getXxcsoWhere550LookupVO()
  {
    return (XxcsoConsciousLookupListVOImpl)findViewObject("XxcsoWhere550LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere560LookupVO
   */
  public XxcsoConsciousLookupListVOImpl getXxcsoWhere560LookupVO()
  {
    return (XxcsoConsciousLookupListVOImpl)findViewObject("XxcsoWhere560LookupVO");
  }


  /**
   * 
   * Container's getter for XxcsoPvDefViewColumnVL2
   */
  public ViewLinkImpl getXxcsoPvDefViewColumnVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefViewColumnVL2");
  }

  /**
   * 
   * Container's getter for XxcsoPvViewColumnCopyVO
   */
  public XxcsoPvViewColumnFullVOImpl getXxcsoPvViewColumnCopyVO()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("XxcsoPvViewColumnCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoVendorTypeListVO1
   */
  public XxcsoVendorTypeListVOImpl getXxcsoVendorTypeListVO1()
  {
    return (XxcsoVendorTypeListVOImpl)findViewObject("XxcsoVendorTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoWhere790LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere790LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere790LookupVO");
  }


}